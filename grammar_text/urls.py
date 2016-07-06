# coding: utf-8
from rest_framework import routers
from . import views


router = routers.SimpleRouter()
router.register(r'phrases', views.PhraseViewset)
urlpatterns = router.urls
