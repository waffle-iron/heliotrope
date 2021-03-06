require 'date'

module Import
  class RowData
    attr_reader :row, :attrs

    def data_for_monograph(row, attrs)
      title = Array(row['Title'].split(';')).map(&:strip)
      attrs['title'] = title
      attrs['creator_family_name'] = creator_family_name(row)
      attrs['creator_given_name'] = creator_given_name(row)
    end

    def data_for_asset(row_num, row, file_attrs)
      missing_fields_errors = []
      controlled_vocab_errors = []
      date_errors = []

      # TODO: raise an error if file name is missing and it's not explicitly an external resource
      # ... not going to do this until I know how to attach it as an external resource!
      #
      # if row['File Name'].blank? && row['Externally-Hosted Resource'] != 'yes'
      #   puts "Row #{row_num}: File name missing and not external resource!"
      #   next
      # end

      FIELDS.each do |field|
        if !row[field[:field_name]].blank?
          is_multivalued = field[:multivalued]
          field_values = split_field_values_to_array(row[field[:field_name]], is_multivalued)

          if field[:acceptable_values]
            field_value_acceptable(field[:field_name], field[:acceptable_values], field_values, controlled_vocab_errors)
          end
          if field[:date_format]
            field_values = field_check_dates(field[:field_name], field_values, date_errors)
            next if field_values.blank?
          end
          file_attrs[field[:metadata_name]] = return_scalar_or_multivalued(field_values, is_multivalued)
        elsif field[:required] == true
          # add to array of missing stuff
          # missing_required_fields.add(row[field[:field_name']])
          missing_fields_errors << field[:field_name]
        end
      end

      file_attrs['creator_family_name'] = creator_family_name(row)
      file_attrs['creator_given_name'] = creator_given_name(row)

      combine_field_errors(row_num, missing_fields_errors, controlled_vocab_errors, date_errors)
    end

    private

      def split_field_values_to_array(sheet_value, is_multivalued)
        if is_multivalued == :yes_split
          Array(sheet_value.split(';')).map(&:strip)
        else
          Array(sheet_value.strip)
        end
      end

      def return_scalar_or_multivalued(field_values, is_multivalued)
        is_multivalued == :no ? field_values.first : field_values
      end

      def field_value_acceptable(field_name, acceptable_values, actual_values, controlled_vocab_errors)
        actual_values.each do |actual_value|
          unless acceptable_values.include? actual_value
            controlled_vocab_errors << field_name + ' - "' + actual_value + '"'
          end
        end
      end

      def field_check_dates(field_name, actual_values, date_errors)
        output_dates = []
        actual_values.each do |actual_value|
          fixed_date = output_date(actual_value)
          if !actual_value.blank? && actual_value.casecmp('perpetuity') != 0 && fixed_date.blank?
            date_errors << field_name + ': "' + actual_value + '"'
          elsif !fixed_date.blank?
            output_dates << fixed_date
          end
        end
        output_dates
      end

      def output_date(date_string)
        y = m = d = ''
        if date_string[/\d{4}-\d{2}-\d{2}/]
          y, m, d = date_string.split '-'
        elsif date_string[/\d{4}-\d{2}/]
          y, m = date_string.split '-'
          d = '01'
        elsif date_string[/\d{4}/]
          y = date_string
          m = d = '01'
        end
        return nil unless Date.valid_date?(y.to_i, m.to_i, d.to_i)
        y + '-' + m + '-' + d
      end

      def creator_family_name(row)
        return unless row['Primary Creator Last Name']
        row['Primary Creator Last Name'].strip
      end

      def creator_given_name(row)
        return unless row['Primary Creator First Name']
        row['Primary Creator First Name'].strip
      end

      def combine_field_errors(row_num, missing_fields_errors, controlled_vocab_errors, date_errors)
        message = ''
        message += "\n\nRow #{row_num} has errors:\n" unless missing_fields_errors.empty? && controlled_vocab_errors.empty?
        unless missing_fields_errors.empty?
          message += "missing required fields: \n" + missing_fields_errors.join(', ')
        end
        unless controlled_vocab_errors.empty?
          message += "\nunacceptable values for: \n" + controlled_vocab_errors.join(', ')
        end
        unless date_errors.empty?
          message += "\nthese dates cannot be padded to a YYYY-MM-DD value: \n" + date_errors.join(', ')
        end
        message
      end
  end
end
