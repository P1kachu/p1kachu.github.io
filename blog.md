---
layout: default
title: Blog archive
---
<div class="page-content wc-container">
  <h1>Blog Archive</h1>
  {% for post in site.posts %}
        {% unless post.writeup or post.hidden %}
  	        {% capture currentyear %}{{post.date | date: "%Y"}}{% endcapture %}
  	        {% if currentyear != year %}
    	        {% unless forloop.first %}</ul>{% endunless %}
    		        <h5>{{ currentyear }}</h5>
    		        <ul class="posts">
    		        {% capture year %}{{currentyear}}{% endcapture %}
  		        {% endif %}
        <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></li>
        {% endunless %}
{% endfor %}
</div>
