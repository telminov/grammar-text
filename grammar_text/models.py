# coding: utf-8
from django.db import models
from . import consts


class Phrase(models.Model):
    text = models.TextField()
    is_default = models.BooleanField()

    def __str__(self):
        return self.text

    class Meta:
        ordering = ('is_default', 'text')


class PhraseParam(models.Model):
    phrase = models.ForeignKey(Phrase, related_name='params')
    type = models.CharField(max_length=50, choices=consts.PHRASE_PARAM_TYPE_CHOICES)
    params = models.TextField(help_text='JSON', blank=True)


class PhraseAlias(models.Model):
    phrase = models.ForeignKey(Phrase, related_name='aliases')
    alias = models.TextField()

    def __str__(self):
        return self.alias

