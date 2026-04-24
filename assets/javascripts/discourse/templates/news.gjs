import { htmlSafe } from "@ember/template";
import DiscoveryTopicsList from "discourse/components/discovery-topics-list";
import List from "discourse/components/topic-list/list";
import TopicLink from "discourse/components/topic-list/topic-link";
import formatDate from "discourse/helpers/format-date";
import { i18n } from "discourse-i18n";

<template>
  <div class="topic-list-contents">
    <DiscoveryTopicsList
      @model={{@model}}
      @incomingCount={{@controller.topicTrackingState.incomingCount}}
      @bulkSelectHelper={{@controller.bulkSelectHelper}}
    >
      {{#if @controller.hasTopics}}
        <List
          @top={{@controller.top}}
          @showTopicPostBadges={{@controller.showTopicPostBadges}}
          @showPosters={{true}}
          @canBulkSelect={{@controller.canBulkSelect}}
          @bulkSelectHelper={{@controller.bulkSelectHelper}}
          @changeSort={{@controller.changeSort}}
          @hideCategory={{@model.hideCategory}}
          @order={{@controller.order}}
          @ascending={{@controller.ascending}}
          @expandGloballyPinned={{@controller.expandGloballyPinned}}
          @expandAllPinned={{@controller.expandAllPinned}}
          @category={{@controller.category}}
          @topics={{@model.topics}}
          @discoveryList={{true}}
          @listContext="discovery"
        />
      {{/if}}
    </DiscoveryTopicsList>
  </div>

  {{#if @controller.showSidebar}}
    <div class="sidebar">
      {{#if @controller.showSidebarTopics}}
        <div class="sidebar-title">
          {{i18n "news.sidebar_topics_title"}}
        </div>
        <ul>
          {{#each @model.sidebarTopics as |topic|}}
            <li>
              <div class="sidebar-topic-title">
                <TopicLink @topic={{topic}} />
              </div>
              <div class="sidebar-topic-meta">
                <span>{{formatDate topic.bumpedAt leaveAgo="true"}}</span>
                <span>{{i18n "changed_by" author=topic.creator.username}}</span>
                {{#if topic.category}}
                  <span>{{htmlSafe (i18n "in_category" basicCategoryLink=topic.basicCategoryLinkHtml)}}</span>
                {{/if}}
              </div>
            </li>
          {{/each}}
        </ul>
      {{/if}}
    </div>
  {{/if}}
</template>
