# coding: utf-8
# python setup.py sdist register upload
from setuptools import setup, find_packages


def get_requires():
    with open('requirements.txt') as requirements_file:
        return requirements_file.readlines()

setup(
    name='grammar_text',
    version='0.0.4',
    description='Text with grammar.',
    author='Telminov Sergey',
    author_email='sergey@telminov.ru',
    url='https://github.com/telminov/grammar-text',
    include_package_data=True,
    packages=find_packages(),
    license='The MIT License',
    install_requires=get_requires()
)
