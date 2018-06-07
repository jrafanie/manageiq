describe CustomizationTemplate do
  context "unique name validation" do
    let(:pxe_image_type) { FactoryGirl.create(:pxe_image_type) }

    it "doesn't allow same name in same region with the same pxe_image_type" do
      pit = FactoryGirl.create(:pxe_image_type)
      FactoryGirl.create(:customization_template, :name => "fred", :pxe_image_type => pit)
      expect { FactoryGirl.create(:customization_template, :name => "fred", :pxe_image_type => pit) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "doesn't allow same name in same region with the different pxe_image_type" do
      FactoryGirl.create(:customization_template, :name => "fred", :pxe_image_type => FactoryGirl.create(:pxe_image_type))
      expect { FactoryGirl.create(:customization_template, :name => "fred", :pxe_image_type => FactoryGirl.create(:pxe_image_type)) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "allows different names with the same pxe_image_type in same region" do
      FactoryGirl.create(:customization_template, :name => "fred", :pxe_image_type => pxe_image_type)
      FactoryGirl.create(:customization_template, :name => "nick", :pxe_image_type => pxe_image_type)
      expect(described_class.count).to eq(2)

      first, second = described_class.all
      expect(first.name).to_not eq(second.name)
      expect(first.pxe_image_type).to eq(second.pxe_image_type)
      expect(ApplicationRecord.id_to_region(first.id)).to eq(ApplicationRecord.id_to_region(second.id))
    end

    it "allow same name, nil pxe_image_types in different regions (for system seeding)" do
      system_template   = described_class.create!(:system => true, :name => "nick")
      other_template_id = ApplicationRecord.id_in_region(system_template.id, ApplicationRecord.my_region_number + 1)
      described_class.create!(:system => true, :name => "nick", :id => other_template_id)

      first, second = described_class.all
      expect(first.name).to eq(second.name)
      expect(first.pxe_image_type).to be nil
      expect(first.pxe_image_type).to eq(second.pxe_image_type)
      expect(ApplicationRecord.id_to_region(first.id)).to_not eq(ApplicationRecord.id_to_region(second.id))
    end

    it "allows same name, different pxe_image_types in different regions" do
      template          = FactoryGirl.create(:customization_template, :name => "nick", :pxe_image_type => pxe_image_type)
      other_template_id = ApplicationRecord.id_in_region(template.id, MiqRegion.my_region_number + 1)
      other_pit_id      = ApplicationRecord.id_in_region(pxe_image_type.id, MiqRegion.my_region_number + 1)
      other_pit         = FactoryGirl.create(:pxe_image_type, :id => other_pit_id)
      FactoryGirl.create(:customization_template, :name => "nick", :pxe_image_type => other_pit, :id => other_template_id)

      first, second = described_class.all
      expect(first.name).to eq(second.name)
      expect(first.pxe_image_type).to_not eq(second.pxe_image_type)
      expect(ApplicationRecord.id_to_region(first.id)).to_not eq(ApplicationRecord.id_to_region(second.id))
    end
  end
end
