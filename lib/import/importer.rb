module Import
  class Importer
    attr_reader :root_dir, :press_subdomain, :monograph_title, :visibility

    def initialize(root_dir, press_subdomain, visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
      @root_dir = root_dir
      @press_subdomain = press_subdomain
      @visibility = visibility
    end

    def run(interaction = false, monograph_title = '', test = false)
      validate_press
      csv_files.each do |file|
        errors = ''
        attrs = CSVParser.new(file).attributes(errors)
        monograph_attrs = attrs.delete('monograph')
        sections = attrs.delete('sections')

        # if there is a command-line monograph title then use it
        monograph_attrs['title'] = Array(monograph_title) unless monograph_title.blank?

        # find files now (stop everything ASAP if not found or duplicates found)
        add_full_file_paths(monograph_attrs)
        sections.each do |_, section_attrs|
          add_full_file_paths(section_attrs)
        end

        optional_early_exit(interaction, errors, test)

        monograph_file_attrs = monograph_attrs.delete('files_metadata')
        monograph_attrs = add_command_line_attrs(monograph_attrs, 'monograph')
        monograph_builder = MonographBuilder.new(user, monograph_attrs)
        monograph_builder.run

        monograph = monograph_builder.curation_concern
        update_fileset_metadata(monograph, monograph_file_attrs)
        monograph_id = monograph.id

        sections.each do |_, section_attrs|
          section_files_attrs = section_attrs.delete('files_metadata')
          section_attrs['monograph_id'] = monograph_id
          section_attrs = add_command_line_attrs(section_attrs, 'section')
          section_builder = SectionBuilder.new(user, section_attrs)
          section_builder.run

          section = section_builder.curation_concern
          update_fileset_metadata(section, section_files_attrs)
          # add section to monograph
          monograph.ordered_members << section
          monograph.save!
        end
      end
    end

    private

      def validate_press
        unless Press.exists?(subdomain: press_subdomain)
          raise "No press found with subdomain: '#{press_subdomain}'"
        end
      end

      def csv_files
        fail "Directory not found: #{root_dir}" unless File.exist?(root_dir)
        @csv_files ||= Dir.glob(File.join(root_dir, '*.csv'))
      end

      def add_command_line_attrs(attrs, type)
        if type == 'monograph'
          attributes = attrs.merge('press' => press_subdomain, 'visibility' => visibility)
        elsif type == 'section'
          attributes = attrs.merge('visibility' => visibility)
        end
        attributes
      end

      def add_full_file_paths(attrs)
        attrs['files'] = attrs['files'].map do |file|
          File.new(find_file(file))
        end
      end

      def find_file(file_name)
        match = Dir.glob("#{root_dir}/**/#{file_name}")
        if match.empty?
          raise "'File #{file_name}' not found anywhere under '#{root_dir}'"
        elsif match.count > 1
          raise "More than one file found with name: '#{file_name}'"
        end
        match.first
      end

      def user
        @user ||= DummyUser.new(user_key: 'system')
      end

      # The 'attrs' parameter is an array of hashes.
      # Each hash in the array is a set of attributes for one
      # FileSet.  The array is in the correct order to match
      # the order of the filesets in the ordered_members list.
      def update_fileset_metadata(work, attrs)
        work.ordered_members.to_a.each_with_index do |member, i|
          builder = FileSetBuilder.new(member, user, attrs[i])
          builder.run
        end
      end

      def optional_early_exit(interaction, errors, test)
        if interaction && !errors.blank?
          puts errors
          puts "\n\nERRORS IN DATA! Please review the errors above.\n"
          exit if test == true
          puts "Do you wish to continue (y/n)?"
          continue = gets
          exit unless continue.downcase.first == 'y'
        end
        # command-line option to exit
        exit if test == true
      end
  end
end
