# frozen_string_literal: true

RSpec.describe "News page", type: :system do
  fab!(:category)
  fab!(:topic) { Fabricate(:topic, category: category) }
  fab!(:post) { Fabricate(:post, topic: topic) }

  before do
    SiteSetting.discourse_news_enabled = true
    SiteSetting.discourse_news_source = "category"
    SiteSetting.discourse_news_category = category.id.to_s
  end

  it "displays the news page with topics from the configured category" do
    visit "/news"

    expect(page).to have_css("body.news")
    expect(page).to have_css(".news-item")
    expect(page).to have_content(topic.title)
  end

  it "shows the news header button" do
    visit "/"

    expect(page).to have_css("a.header-nav-link.news[href='/news']")
  end

  it "marks the header button as active on the news route" do
    visit "/news"

    expect(page).to have_css("a.header-nav-link.news.active")
  end

  context "with title below image setting enabled" do
    before { SiteSetting.discourse_news_title_below_image = true }

    it "displays title after the thumbnail" do
      topic.update!(image_url: "https://example.com/image.jpg")

      visit "/news"

      within(".news-item") do
        expect(page).to have_css(".news-item-thumbnail + .news-item-title")
      end
    end
  end
end
