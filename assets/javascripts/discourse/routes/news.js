import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import buildTopicRoute from "discourse/routes/build-topic-route";

export default class NewsRoute extends buildTopicRoute("news") {
  @service siteSettings;
  @service site;
  @service store;

  async #fetchSidebarTopics() {
    if (
      !this.siteSettings.discourse_news_sidebar_topic_list ||
      this.site.mobileView
    ) {
      return null;
    }

    const filter =
      this.siteSettings.discourse_news_sidebar_topic_list_filter || "latest";
    const list = await this.store.findFiltered("topicList", { filter });
    const limit =
      this.siteSettings.discourse_news_sidebar_topic_list_limit || 10;
    return list.topics.slice(0, limit);
  }

  async model(data, transition) {
    const sidebarTopics = await this.#fetchSidebarTopics();

    if (this.siteSettings.discourse_news_source === "rss") {
      const result = await ajax("/news").catch(popupAjaxError);
      return {
        filter: "",
        topics: result.map((t) => ({
          title: t.title,
          description: t.description,
          url: t.url,
          image_url: t.image_url,
          rss: true,
        })),
        sidebarTopics,
      };
    }

    const base = await super.model(data, transition);
    return Object.assign(base, { sidebarTopics });
  }

  setupController(controller, model) {
    super.setupController(controller, model);
  }
}
