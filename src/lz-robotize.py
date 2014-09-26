#!/usr/bin/env lz2lv2
# Created on Fri 2014-09-19 19:06:26 BRT
"""
Simple voice robotization LV2 plugin using the AudioLazy Python DSP.
"""

class Metadata:
  name = "Robotize"

  author = "Danilo de Jesus da Silva Bellini"
  author_homepage = "http://github.com/danilobellini"
  author_email = "danilo.bellini" + "@" + "gmail.com"

  license = "GPLv3"

  uri = author_homepage + "/lz-plugins-lv2/" + name.lower()
  lv2class = "Spectral"
