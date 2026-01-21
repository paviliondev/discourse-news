import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { htmlSafe } from "@ember/template";
import ShareTopicModal from "discourse/components/modal/share-topic";
import icon from "discourse/helpers/d-icon";
import number from "discourse/helpers/number";
import { emojiUnescape } from "discourse/lib/text";
import { i18n } from "discourse-i18n";
import NewsItemTitle from "./news-item-title";

export default class NewsItem extends Component {
  @service siteSettings;
  @service modal;

  get titleBelowImage() {
    return this.siteSettings.discourse_news_title_below_image;
  }

  get newsBody() {
    const { topic } = this.args;
    if (topic.rss) {
      return htmlSafe(topic.description);
    }
    return htmlSafe(emojiUnescape(topic.news_body));
  }

  @action
  openShareModal() {
    this.modal.show(ShareTopicModal, {
      model: {
        category: this.args.topic.category,
        topic: this.args.topic,
      },
    });
  }

  <template>
    <td class="main-link news-item clearfix" colspan={{@titleColSpan}}>
      {{#unless this.titleBelowImage}}
        <NewsItemTitle @topic={{@topic}} />
      {{/unless}}

      {{#if @topic.image_url}}
        <div class="news-item-thumbnail">
          <a href={{@topic.url}}>
            <img src={{@topic.image_url}} loading="lazy" alt="" />
          </a>
        </div>
      {{/if}}

      {{#if this.titleBelowImage}}
        <NewsItemTitle @topic={{@topic}} />
      {{/if}}

      <div class="news-item-body">
        {{this.newsBody}}
      </div>

      <div class="news-item-gutter">
        {{#if @showReplies}}
          <div class="news-item-replies posts-map" title={{@title}}>
            <a href class="posts-map badge-posts">{{number
                @topic.replyCount
              }}</a>
            <span>{{i18n "replies_lowercase" count=@topic.replyCount}}</span>
          </div>
        {{/if}}

        <button
          class="share btn-flat no-text btn-icon"
          type="button"
          {{on "click" this.openShareModal}}
        >
          {{icon "link"}}
        </button>
      </div>
    </td>
  </template>
}
