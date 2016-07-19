# coding: utf-8
from django import forms
from django.core.urlresolvers import reverse
from django.template.loader import render_to_string


class PhraseWidget(forms.TextInput):
    class Media:
        js = ('grammar_text/main.js', )

    def render(self, name, value, attrs=None):
        c = {
            'input_html': super(PhraseWidget, self).render(name, value, attrs=attrs),
            'phrases_url': reverse('phrases-list'),
            'input_id': attrs['id'],
        }
        html = render_to_string('grammar_text/widget.html', c)
        return html


