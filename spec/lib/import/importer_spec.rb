require 'rails_helper'
require 'import'

describe Import::Importer do
  let(:public_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:private_vis) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }

  let(:root_dir) { File.join(fixture_path, 'csv', 'import_sections') }
  let(:press) { Press.find_or_create_by(subdomain: 'umich') }
  let(:importer) { described_class.new(root_dir, press.subdomain, visibility) }
  let(:visibility) { public_vis }

  before do
    # Don't print status messages during specs
    allow($stdout).to receive(:puts)
  end

  describe 'initializer' do
    it 'has a root directory' do
      expect(importer.root_dir).to eq root_dir
    end

    it 'has a press' do
      expect(importer.press_subdomain).to eq press.subdomain
    end

    it 'has a visibility' do
      expect(importer.visibility).to eq public_vis
    end

    context 'default visibility' do
      let(:importer) { described_class.new(root_dir, press.subdomain) }

      it 'is private' do
        expect(importer.visibility).to eq private_vis
      end
    end
  end

  describe '#run' do
    before do
      stub_out_redis
      Monograph.destroy_all
      Section.destroy_all
    end

    context 'when the importer runs successfully' do
      it 'imports the monograph, sections and files' do
        expect { importer.run }
          .to change { Monograph.count }.by(1)
          .and(change { Section.count }.by(2))
          .and(change { FileSet.count }.by(8))

        monograph = Monograph.first
        expect(monograph.visibility).to eq public_vis

        section = Section.first
        expect(section.visibility).to eq public_vis

        # Test that the FileSetBuilder got called to add the
        # metadata to the FileSets.
        shipwreck = monograph.ordered_members.to_a.first
        expect(shipwreck.title).to eq ['Monograph Shipwreck']
        miranda = monograph.ordered_members.to_a.second
        expect(miranda.title).to eq ['Monograph Miranda']

        shipwreck = section.ordered_members.to_a.first
        expect(shipwreck.title).to eq ['Section 1 Shipwreck']
        miranda = section.ordered_members.to_a.second
        expect(miranda.title).to eq ['Section 1 Miranda']
      end
    end

    context 'when the root directory doesnt exist' do
      let(:root_dir) { File.join(fixture_path, 'bad_directory') }
      it 'raises an exception' do
        expect { importer.run }.to raise_error(/Directory not found/)
      end
    end

    context 'when the press is invalid' do
      let(:press) { Press.new(subdomain: 'incorrect press') }

      it 'raises an exception' do
        expect { importer.run }.to raise_error(/No press found with subdomain: 'incorrect press'/)
      end
    end
  end
end
