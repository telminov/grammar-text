# coding: utf-8
from rest_framework import serializers
from . import models


class PhraseParam(serializers.ModelSerializer):
    class Meta:
        model = models.PhraseParam
        exclude = ('id', 'phrase')


class Phrase(serializers.ModelSerializer):
    params = PhraseParam(many=True)
    aliases = serializers.SerializerMethodField()

    class Meta:
        model = models.Phrase

    def get_aliases(self, obj):
        return [alias.alias for alias in obj.aliases.all()]
