# coding: utf-8
from rest_framework import viewsets
from . import models
from . import serializers


class PhraseViewset(viewsets.ReadOnlyModelViewSet):
    queryset = models.Phrase.objects.all()
    serializer_class = serializers.Phrase

    def filter_queryset(self, *args, **kwargs):
        queryset = super(PhraseViewset, self).filter_queryset(*args, **kwargs)
        if self.request.GET.get('id'):
            queryset = queryset.filter(id__in=self.request.GET.getlist('id'))
        return queryset
