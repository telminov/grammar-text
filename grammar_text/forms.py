# coding: utf-8
from django import forms
from django.core.urlresolvers import reverse
from django.template.loader import render_to_string


class PhraseWidget(forms.TextInput):
    class Media:
        js = ('grammar_text/main.js', )

    def __init__(self, *args, **kwargs):
        phrases_qs = kwargs.pop('phrases_qs', None)     # limitation of phrase choices
        super(PhraseWidget, self).__init__(*args, **kwargs)
        self.phrases_qs = phrases_qs

    def render(self, name, value, attrs=None):
        c = {
            'input_html': super(PhraseWidget, self).render(name, value, attrs=attrs),
            'phrases_url': reverse('phrases-list'),
            'input_id': attrs['id'],
        }
        if self.phrases_qs:
            c['phrases_url'] += '?' + '&'.join(['id=%s' % id for id in self.phrases_qs.values_list('id', flat=True)])

        html = render_to_string('grammar_text/widget.html', c)
        return html


