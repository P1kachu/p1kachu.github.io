---
layout: default
title: Writeups list
---
<div class="page-content wc-container">
  <h1>CTF Writeups</h1>
  {% for post in site.posts %}
        {% if post.writeup %}
          	{% capture currentyear %}{{post.date | date: "%Y"}}{% endcapture %}
  	        {% if currentyear != year %}
    	        {% unless forloop.first %}</ul>{% endunless %}
    		        <h5>{{ currentyear }}</h5>
    		        <ul class="posts">
    		        {% capture year %}{{currentyear}}{% endcapture %}
  		        {% endif %}
        <li><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></li>
    {% endif %}
{% endfor %}
</div>
