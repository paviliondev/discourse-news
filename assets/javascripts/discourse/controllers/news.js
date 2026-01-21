import DiscoveryListController from 'discourse/controllers/discovery/list';

export default class NewsController extends DiscoveryListController {
  get showSidebar() {
    return this.showSidebarTopics && !this.site.mobileView;
  }

  get showSidebarTopics() {
    return this.sidebarTopics && this.siteSettings.discourse_news_sidebar_topic_list;
  }
}