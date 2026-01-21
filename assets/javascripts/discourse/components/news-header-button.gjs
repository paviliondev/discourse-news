import Component from "@glimmer/component";
import { service } from "@ember/service";
import concatClass from "discourse/helpers/concat-class";
import icon from "discourse/helpers/d-icon";
import { i18n } from "discourse-i18n";

export default class NewsHeaderButton extends Component {
  @service router;
  @service siteSettings;

  get isActive() {
    return this.router.currentRouteName === "news";
  }

  get iconName() {
    const setting = this.siteSettings.discourse_news_icon;
    return setting && !setting.includes("/") ? setting : null;
  }

  get iconImageUrl() {
    const setting = this.siteSettings.discourse_news_icon;
    return setting?.includes("/") ? setting : null;
  }

  <template>
    <a
      href="/news"
      class={{concatClass "header-nav-link news" (if this.isActive "active")}}
    >
      {{#if this.iconImageUrl}}
        <img src={{this.iconImageUrl}} alt="" />
      {{else if this.iconName}}
        {{icon this.iconName}}
      {{/if}}
      <span>{{i18n "filters.news.title"}}</span>
    </a>
  </template>
}
