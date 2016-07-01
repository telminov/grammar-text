# coding: utf-8
from django.contrib import admin
from . import models


class PhraseParamInline(admin.StackedInline):
    model = models.PhraseParam
    extra = 0


class PhraseAliasInline(admin.StackedInline):
    model = models.PhraseAlias
    extra = 0


class Phrase(admin.ModelAdmin):
    inlines = (PhraseParamInline, PhraseAliasInline)
    list_display = ('text', 'get_aliases')

    def get_aliases(self, obj):
        return ', '.join(map(str, obj.aliases.all()))

admin.site.register(models.Phrase, Phrase)
