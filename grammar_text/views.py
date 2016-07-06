# coding: utf-8
from rest_framework import viewsets
from . import models
from . import serializers


class PhraseViewset(viewsets.ReadOnlyModelViewSet):
    queryset = models.Phrase.objects.all()
    serializer_class = serializers.Phrase
