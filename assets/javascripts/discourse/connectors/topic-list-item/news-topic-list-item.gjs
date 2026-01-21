import Component from "@glimmer/component";
import { service } from "@ember/service";
import bodyClass from "discourse/helpers/body-class";
import NewsItem from "../../components/news-item";

export default class NewsTopicListItem extends Component {
  @service router;
  @service siteSettings;

  get isNewsRoute() {
    return this.router.currentRouteName === "news";
  }

  get showReplies() {
    return (
      this.siteSettings.discourse_news_source === "category" &&
      this.siteSettings.discourse_news_show_reply_count
    );
  }

  <template>
    {{#if this.isNewsRoute}}
      {{bodyClass "news"}}
      <NewsItem @topic={{@topic}} @showReplies={{this.showReplies}} />
    {{else}}
      {{yield}}
    {{/if}}
  </template>
}
