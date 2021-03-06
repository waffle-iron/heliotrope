module Import
  extend ActiveSupport::Autoload
  autoload :DummyUser
  autoload :MonographBuilder
  autoload :SectionBuilder
  autoload :FileSetBuilder
  autoload :Importer
  autoload :CSVParser
  autoload :RowData

  # something to note is that the multivalued :yes/:no values mirror the model, such that assignment will work properly as a scalar or array...
  # ... the third :yes_split means that this is a field we actually want to *use* as multivalued, and so will split the CSV field on semicolons to do so

  FIELDS =
    [
      # for now leave File Name separate, but eventually when external resources are figured out it should go in here too with required => false
      # { field_name: 'File Name', metadata_name: 'title', required: true, multivalued: :no },
      { field_name: 'Title', metadata_name: 'title', required: true, multivalued: :yes },
      { field_name: 'Resource Type', metadata_name: 'resource_type', required: true, multivalued: :yes, acceptable_values: ['audio', 'image', 'dataset', 'table', '3D model', 'text', 'video'] },
      { field_name: 'Externally Hosted Resource', metadata_name: 'external_resource', required: true, multivalued: :no, acceptable_values: ['yes', 'no'] },
      { field_name: 'Caption', metadata_name: 'caption', required: true, multivalued: :yes },
      { field_name: 'Alternative Text', metadata_name: 'alt_text', required: true, multivalued: :yes },
      { field_name: 'Book and Platform (BP) or Platform-only (P)', metadata_name: 'exclusive_to_platform', required: true, multivalued: :no, acceptable_values: ['BP', 'P'] },
      { field_name: 'Copyright Holder', metadata_name: 'copyright_holder', required: true, multivalued: :no },
      { field_name: 'Allow High-Res Display?', metadata_name: 'allow_hi_res', required: true, multivalued: :no, acceptable_values: ['yes', 'no', 'Not hosted on the platform'] },
      { field_name: 'Allow Download?', metadata_name: 'allow_download', required: true, multivalued: :no, acceptable_values: ['yes', 'no', 'Not hosted on the platform'] },
      { field_name: 'Copyright Status', metadata_name: 'copyright_status', required: true, multivalued: :no, acceptable_values: ['in-copyright', 'public domain', 'status unknown'] },
      { field_name: 'Rights Granted', metadata_name: 'rights_granted', required: false, multivalued: :no },
      { field_name: 'Rights Granted - Creative Commons',
        metadata_name: 'rights_granted_creative_commons',
        required: false,
        multivalued: :no,
        acceptable_values: [
          'Creative Commons Attribution license, 3.0 Unported',
          'Creative Commons Attribution-NoDerivatives license, 3.0 Unported',
          'Creative Commons Attribution-NonCommercial-NoDerivatives license, 3.0 Unported',
          'Creative Commons Attribution-NonCommercial license, 3.0 Unported',
          'Creative Commons Attribution-NonCommercial-ShareAlike license, 3.0 Unported',
          'Creative Commons Attribution-ShareAlike license, 3.0 Unported',
          'Creative Commons Zero license (implies pd)',
          'Creative Commons Attribution 4.0 International license',
          'Creative Commons Attribution-NoDerivatives 4.0 International license',
          'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International license',
          'Creative Commons Attribution-NonCommercial 4.0 International license',
          'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International license',
          'Creative Commons Attribution-ShareAlike 4.0 International license'] },
      { field_name: 'Permissions Expiration Date', metadata_name: 'permissions_expiration_date', required: false, multivalued: :no, date_format: true },
      { field_name: 'After Expiration: Allow Display?', metadata_name: 'allow_display_after_expiration', required: false, multivalued: :no, acceptable_values: ['none', 'high-res', 'low-res', 'Not hosted on the platform'] },
      { field_name: 'After Expiration: Allow Download?', metadata_name: 'allow_download_after_expiration', required: false, multivalued: :no, acceptable_values: ['yes', 'no', 'Not hosted on the platform'] },
      { field_name: 'Credit Line', metadata_name: 'credit_line', required: false, multivalued: :no },
      { field_name: 'Holding Contact', metadata_name: 'holding_contact', required: false, multivalued: :no },
      { field_name: 'Persistent ID - Display on Platform', metadata_name: 'ext_url_doi_or_handle', required: false, multivalued: :no },
      { field_name: 'Persistent ID - XML for CrossRef', metadata_name: 'use_crossref_xml', required: false, multivalued: :no, acceptable_values: ['yes', 'no'] },
      { field_name: 'Persistent ID - Handle', metadata_name: 'book_needs_handles', required: false, multivalued: :no, acceptable_values: ['yes', 'no'] },
      { field_name: 'Content Type', metadata_name: 'content_type', required: false, multivalued: :yes },
      { field_name: 'Primary Creator Role', metadata_name: 'primary_creator_role', required: false, multivalued: :yes_split },
      { field_name: 'Additional Creator(s)', metadata_name: 'contributor', required: false, multivalued: :yes_split },
      { field_name: 'Sort Date', metadata_name: 'sort_date', required: false, multivalued: :no, date_format: true },
      { field_name: 'Display Date', metadata_name: 'display_date', required: false, multivalued: :no },
      { field_name: 'Description', metadata_name: 'description', required: false, multivalued: :yes },
      { field_name: 'Keywords', metadata_name: 'keywords', required: false, multivalued: :yes_split },
      { field_name: 'Language', metadata_name: 'language', required: false, multivalued: :yes_split },
      { field_name: 'Transcript', metadata_name: 'transcript', required: false, multivalued: :no },
      { field_name: 'Translation', metadata_name: 'translation', required: false, multivalued: :yes_split }
    ].freeze
end
