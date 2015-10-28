require "spec_helper"

describe "Data Access workflow", reset: false do
  downloadable_collection_id = 'C90762182-LAADS'
  downloadable_collection_title = 'MODIS/Aqua Calibrated Radiances 5-Min L1B Swath 250m V005'

  non_downloadable_collection_id = 'C179001887-SEDAC'
  non_downloadable_collection_title = '2000 Pilot Environmental Sustainability Index (ESI)'

  context "when a malicious user attempts an XSS attack using the data access back link" do
    before(:each) do
      load_page :root
      login
      visit "/data/configure?p=!#{downloadable_collection_id}&back=javascript:alert(%27ohai%27)//"
    end

    after :each do
      Capybara.reset_sessions!
    end

    it "uses a safe back link" do
      expect(page).to have_link("Back to Search Session")
      expect(page).to have_css("a[href^=\"/search/collections?p=!#{downloadable_collection_id}\"]")
    end
  end

  context "when the user is not logged in" do
    before(:each) do
      load_page :search, project: [downloadable_collection_id, non_downloadable_collection_id], view: :project
      wait_for_xhr
      click_link "Retrieve project data"
      wait_for_xhr
    end

    after :each do
      Capybara.reset_sessions!
    end

    it "forces the user to login before showing data access page" do
      expect(page).to have_content('EOSDIS Earthdata Login')
    end
  end

  context "when the user is logged in" do
    before(:all) do
      load_page :search, {project: [downloadable_collection_id, non_downloadable_collection_id], view: :project, temporal: ['2014-07-10T00:00:00Z', '2014-07-10T03:59:59Z']}
      login
      click_link "Retrieve project data"
      wait_for_xhr
    end

    after :all do
      Capybara.reset_sessions!
    end

    it "displays a link to return to search results" do
      expect(page).to have_link("Back to Search Session")
      expect(page).to have_css("a[href^=\"/search/project?p=!#{downloadable_collection_id}\"]")
    end

    context "when displaying options for the first of multiple collections" do
      after :all do
        reset_access_page
      end

      it "displays granule information" do
        expect(page).to have_content "27 Granules"
      end

      it 'displays a "continue" button' do
        expect(page).to have_content "Continue"
      end

      it 'displays no "back" button' do
        within(".data-access-content") do
          expect(page).to have_no_content "Back"
        end
      end

      context "when viewing granule list" do
        before :all do
          click_link 'Expand List'
          wait_for_xhr
        end

        after :all do
          click_link 'Hide List'
        end

        it "displays granule information" do
          expect(page).to have_content "MYD02QKM.A2014191.0330.005.2014191162458.hdf"
        end

        it "displays more granules when scrolling" do
          page.execute_script "$('.granule-list div')[0].scrollTop = 10000"
          expect(page).to have_css '.granule-list h5', count: 27
        end

        it "displays an option to download" do
          expect(page).to have_field('Download')
        end

        it "displays options provided by orders" do
          expect(page).to have_field('FtpPushPull')
        end
      end

      context 'and clicking the "continue" button' do
        before :all do
          choose "Download"
          click_button "Continue"
        end

        after :all do
          reset_access_page
        end

        it 'displays the next collection in the list' do
          expect(page).to have_content "Collection Only"
        end
      end
    end

    context "when displaying options for the last of multiple collections" do
      before :all do
        choose "FtpPushPull"
        click_button "Continue"
      end

      after :all do
        reset_access_page
      end

      it "displays granule information" do
        expect(page).to have_content "Collection Only"
      end

      it 'displays a "continue" button to confirm contact information' do
        expect(page).to have_content "Continue"
      end

      it 'displays a "back" button' do
        within(".data-access-content") do
          expect(page).to have_content "Back"
        end
      end

      context 'and clicking the "back" button' do
        before :all do
          click_button "Back"
        end

        it 'displays the previous collection in the list' do
          expect(page).to have_content "27 Granules"
        end
      end
    end

    context "on the final collection's step when contact information is not required" do
      before :all do
        choose "Download"
        click_button "Continue"
      end

      after :all do
        reset_access_page
      end

      it "displays a submit button" do
        expect(page).to have_button("Submit")
      end

      it "does not ask for contact information" do
        expect(page).to have_no_text("Contact Information")
      end

    end

    context "on the final step before submitting when contact information is required" do
      before :all do
        choose "FtpPushPull"
        click_button "Continue"
        click_button "Continue"
      end

      after :all do
        reset_access_page
      end

      it "displays current contact information" do
        account_form = page.find('.account-form')
        expect(account_form).to have_text("Earthdata Search (patrick+edsc@element84.com)")
        expect(account_form).to have_text("EDSC")

        expect(account_form).to have_text("101 N. Columbus St.")
        expect(account_form).to have_text("Suite 200")
        expect(account_form).to have_text("Alexandria, VA 22314")
        expect(account_form).to have_no_text("United States")

        expect(account_form).to have_text("555-555-5555 (Phone)")
        expect(account_form).to have_text("555-555-6666 (Fax)")
      end

      it 'displays a "submit" button' do
        expect(page).to have_content "Submit"
      end

      it 'displays a "back" button' do
        within(".data-access-content") do
          expect(page).to have_content "Back"
        end
      end

      context 'clicking the "edit" button for contact information' do
        before :all do
          click_link 'Edit'
        end

        it "presents a populated form to edit contact information" do
          expect(page).to have_field("First name", with: "Earthdata")
          expect(page).to have_field("Last name", with: "Search")
          expect(page).to have_field("Email", with: "patrick+edsc@element84.com")
          expect(page).to have_field("Organization name", with: "EDSC")
          expect(page).to have_field("Phone number", with: "555-555-5555")
          expect(page).to have_field("Fax number", with: "555-555-6666")
          expect(page).to have_field("Street", with: "101 N. Columbus St.")
          expect(page).to have_field("address_street2", with: "Suite 200")
          expect(page).to have_field("address_street3", with: "")
          expect(page).to have_select("Country", selected: "United States")
          expect(page).to have_select("State", selected: "VA")
          expect(page).to have_field("Zip", with: "22314")
          expect(page).to have_select("Receive delayed access notifications", selected: "Never")
        end

        context "submitting with missing required fields" do
          before :each do
            fill_in "First name", with: ""
            click_on "Submit"
          end

          after :each do
            fill_in "First name", with: "Earthdata"
            # Note: this does not clear the error.  That's not important for this suite.
          end

          it "displays appropriate error messages" do
            expect(page).to have_text('Please fill in all required fields, highlighted below')
          end

          it "keeps the user on the data access page" do
            expect(current_path).to eql('/data/configure')
          end
        end
      end

      context 'clicking the "back" button' do
        before :all do
          click_button "Back"
        end

        after :all do
          click_button "Continue"
        end

        it 'displays the previous collection in the list' do
          expect(page).to have_content "Collection Only"
        end
      end
    end
  end

end
