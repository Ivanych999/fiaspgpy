# -*- encoding: utf-8 -*-
__author__ = 'medvedev.ivan@mail.ru'

import os, datetime

SEVERITY_INFO = 0
SEVERITY_WARNING = 1
SEVERITY_ERROR = 2

SEVERITY_LEVEL = {
			  SEVERITY_INFO: 'info',
			  SEVERITY_WARNING: 'warning',
			  SEVERITY_ERROR: 'error'
			  }

class apylog:
	severity = 0
	
	def __init__(self,severity):
		self.severity = severity

	def addMessage(self,severity,message,ignore_logger_severity=False):
		if self.severity<=severity or ignore_logger_severity:
			print u"{0} at {1}: {2}".format(SEVERITY_LEVEL[severity].capitalize(),datetime.datetime.now().strftime('%d.%m.%Y %H:%M:%S'),message)
