import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";
import TopicLink from "discourse/components/topic-list/topic-link";
import formatDate from "discourse/helpers/format-date";

export default class NewsItemTitle extends Component {
  get rssTitle() {
    return htmlSafe(this.args.topic.title);
  }

  <template>
    <div class="news-item-title">
      <span class="link-top-line">
        {{#if @topic.rss}}
          <a href={{@topic.url}} class="title">{{this.rssTitle}}</a>
        {{else}}
          <TopicLink @topic={{@topic}} />
        {{/if}}
      </span>

      <div class="link-bottom-line">
        <div class="news-item-author">
          {{@topic.creator.displayName}}
        </div>
        {{#if @topic.created_at}}
          <span>|</span>
          <div class="news-item-date">
            {{formatDate @topic.created_at format="medium"}}
          </div>
        {{/if}}
      </div>
    </div>
  </template>
}
