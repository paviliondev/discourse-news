import { service } from "@ember/service";
import DiscoveryListController from "discourse/controllers/discovery/list";

export default class NewsController extends DiscoveryListController {
  @service site;
  @service siteSettings;

  get showSidebar() {
    return this.showSidebarTopics && !this.site.mobileView;
  }

  get showSidebarTopics() {
    return (
      this.model?.sidebarTopics &&
      this.siteSettings.discourse_news_sidebar_topic_list
    );
  }

  get sidebarTopics() {
    return this.model?.sidebarTopics ?? [];
  }
}
