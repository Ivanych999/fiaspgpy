# -*- encoding: utf-8 -*-
__author__ = 'medvedev.ivan@mail.ru'

from dbfread import DBF
from collections import namedtuple
import apylog
import psycopg2
import os, json, threading, time
from Queue import Queue

default_config = {
				  "fias_table_names":["addrobj", "house", "houseint", "landmark", "nordoc", "socrbase", "curentst", "actstat", "operstat", "centerst", "intvstat", "hststat", "eststat", "strstat", "daddrobj", "dhouse", "dhousint", "dlandmark", "dnordoc"],
				  "fias_dtables":{"daddrobj": "addrobj", "dhouse": "house", "dhousint": "houseint", "dlandmark": "landmark", "dnordoc": "nordoc"},
				  "dbf_path": "D:\\Data\\fias_dbf",
				  "pg_parameters": {
						"host": "localhost",
						"port": "5432",
						"dbname": "fias",
						"user": "dataeditor",
						"password": "dataeditor"
						},
				  "data_types": {
					 "integer": {"type": "N"},
					 "character varying": {"type": "C", "length_required": True},
					 "text": {"type": "M"},
					 "date": {"type": "D"}
					 },
				  # {0} - table name, {1} - comma separated columns` names, {2} - comma separated values, {3} - primary key column name, {4} - primary key value
				  "upsert_sql" : """WITH upsert AS (UPDATE {0} SET ({1}) = ({2}) WHERE {3}='{4}' RETURNING *) INSERT INTO {0} ({1}) SELECT {2} WHERE NOT EXISTS (SELECT * FROM upsert);""",
				  "get_pkey_sql": """select attname from pg_attribute where attrelid in (select conindid from pg_constraint where conrelid in (select oid from pg_class where relname = '{0}'));""",
				  "delete_sql" : "DELETE FROM {0} WHERE {1} in (SELECT {1} FROM {2});",
				  "schema_file": "create_fias_schema.sql",
				  "threads_count": 24
				  }

class config:
	config_file = ''
	config_data = {}

	def __init__(self,config_file):
		self.config_file = config_file

	def load_from_file(self):
		try:
			conf = open(self.config_file,'r')
			self.config_data = json.load(conf)
			conf.close()
		except Exception,err:
			self.config_data = default_config


class pgworker:
	host = 'localhost'
	port = '5432'
	dbname = 'fias'
	user = ''
	password = ''
	schema = {}

	def __init__(self,dbname,user,password,host='localhost',port='5432'):
		self.host = host
		self.port = port
		self.dbname = dbname
		self.user = user
		self.password = password

	def _connect(self):
		return psycopg2.connect(database=self.dbname,user=self.user,password=self.password,host=self.host,port=self.port)

	def get_schema(self):
		pass

	def load_schema(self,schema_file):
		result = {"status": "", "data": ""}
		try:
			with open(schema_file,'r') as schema:
				with self._connect() as conn:
					cur = conn.cursor()
					cur.execute(schema.read().format(self.user))
					conn.commit()
					result = {"status": apylog.SEVERITY_INFO, "data": "Schema loaded"}
		except Exception,err:
			result = {"status": apylog.SEVERITY_ERROR, "data": err}
		return result

	def update_schema(self):
		pass

	def get_pkey_name(self,config,tablename):
		result = {"status": "", "data": ""}
		try:
			with self._connect() as conn:
				cur = conn.cursor()
				cur.execute(config.get("get_pkey_sql",default_config["get_pkey_sql"]).format(tablename))
				data = cur.fetchone()
				result = {"status": apylog.SEVERITY_INFO, "data": data[0]}
		except Exception,err:
			result = {"status":apylog.SEVERITY_ERROR, "data": err}
		return result

	@staticmethod
	def _prepareValue(val):
		if val <> None and val <> '':
			if type(val) == int or type(val) == float:
				return '%s' % int(val)
			else:
				return "'%s'" % unicode(val).replace("'","''")
		else:
			return 'null'

	def insert_data(self,tablename,records):
		result = {"status": "", "data": ""}
		lq = ''
		try:
			with self._connect() as conn:
				cur = conn.cursor()
				for row in records:
					statement = "INSERT INTO {0} ({1}) VALUES ({2})".format(tablename,','.join(row.keys()).lower(),','.join('%s' for i in xrange(len(row.values()))))
					if row.values()[0] == 'db9b8f3c-f8a7-4260-a3db-5f5ac0211d99':
						print 1
					cur.execute(statement,tuple(row.values()))
					lq = cur.query
				conn.commit()
				cur.close()
				result = {"status": apylog.SEVERITY_INFO, "data": "%s: all data inserted" % tablename}
		except Exception,err:
			result = {"status": apylog.SEVERITY_ERROR, "data": err.message.decode('utf8')}
		return result

	def upsert_data(self,config,tablename,pkey_name,records):
		result = {"status": "", "data": ""}
		try:
			with self._connect() as conn:
				cur = conn.cursor()
				for row in records:
					#cur.execute(config["upsert_sql"].format(tablename,','.join([f.lower() for f in row.keys()]),','.join([pgworker._prepareValue(val) for val in row.values()]),pkey_name,pgworker._prepareValue(row[pkey_name.upper()])))
					parameters = row.values()
					parameters.append(row[pkey_name.upper()])
					parameters += row.values()
					cur.execute(config["upsert_sql"].format(tablename,','.join(row.keys()).lower(),','.join('%s' for i in xrange(len(row.values()))),pkey_name,'%s'),tuple(parameters))
				conn.commit()
				result = {"status": apylog.SEVERITY_INFO, "data": "All data upserted"}
		except Exception,err:
			result = {"status": apylog.SEVERITY_ERROR, "data": err.message.decode('utf8')}
		return result

	def delete_ddata(self,config,dtable,pkey_name,table):
		result = {"status": "", "data": ""}
		try:
			with self._connect() as conn:
				cur = conn.cursor()
				cur.execute(config["delete_sql"].format(dtable,pkey_name,table))
				conn.commit()
				result = {"status": apylog.SEVERITY_INFO, "data": "All data updated"}
		except Exception,err:
			result = {"status": apylog.SEVERITY_ERROR, "data": err.message.decode('utf8')}
		return result

class dbfreader:
	files_path=''
	files_tables = {}
	encoding='cp866'

	def __init__(self,path,encoding='cp866'):
		self.files_path = path
		self.encoding = encoding

	@staticmethod
	def _type_to_pg(config,type,length,decimal_count):
		if config.get("data_types",""):
			for dt in config["data_types"].keys():
				if config["data_types"][dt].get("type","") == type:
					if config["data_types"][dt].get("length",""):
						if length in config["data_types"][dt]["length"].get("values",[i for i in xrange(1,255)]) and length not in config["data_types"][dt]["length"].get("exclude",[]):
							if config["data_types"][dt].get("length_required",False):
								return "{0}({1})".format(dt,length)
							else:
								return dt
					else:
						return dt

	def _read_schema(self,filename):
		#d_file = DBF(filename, encoding = self.encoding, ignore_missing_memofile=True)
		#fields = d_file.field
		#return
		pass

	def touch(self):
		#if os.path.exists(self.files_path):
		#	for dbf in [d for d in os.listdir(self.files_path) if d.lower().endswith('.dbf')]:
				
		#		data[os.path.basename(dbf).split('.')[0]]
		pass

	def read_files(self,config):
		if os.path.exists(self.files_path):
			for tbl in config.get("fias_table_names",default_config["fias_table_names"]):
				self.files_tables[tbl] = []
			for dbf in [d for d in os.listdir(self.files_path) if d.lower().endswith('.dbf')]:
				filename = dbf.split('.')[0]
				if filename.isalpha():
					if filename.lower() in config.get("fias_table_names",default_config["fias_table_names"]):
						self.files_tables.get(filename.lower(),[]).append(dbf)
				elif filename.isalnum():
					tablename = ''.join([c.lower() for c in filename if c.isalpha()])
					if tablename in config.get("fias_table_names",default_config["fias_table_names"]):
						self.files_tables.get(tablename,[]).append(dbf)
				else:
					continue

	def open_file(self,filename):
		return DBF(os.path.join(self.files_path,filename), encoding = self.encoding, ignore_missing_memofile=True)


class fiasloader:
	config_worker = ''
	pg_worker = ''
	dbf_worker = ''
	logger = ''
	upsertQueue = Queue()
	deleteQueue = Queue()

	def __init__(self,config_file):
		self.logger = apylog.apylog(apylog.SEVERITY_INFO)

		try:
			self.logger.addMessage(apylog.SEVERITY_INFO,'Start loading config')
			self.config_worker = config(config_file)
			self.config_worker.load_from_file()
			self.logger.addMessage(apylog.SEVERITY_INFO,'Config loaded')

			self.logger.addMessage(apylog.SEVERITY_INFO,'Start loading DBF worker')
			self.dbf_worker = dbfreader(self.config_worker.config_data["dbf_path"],self.config_worker.config_data.get("encoding",'cp866'))
			self.logger.addMessage(apylog.SEVERITY_INFO,'DBF worker loaded')

			self.logger.addMessage(apylog.SEVERITY_INFO,'Start read DBF files info')
			self.dbf_worker.read_files(self.config_worker.config_data)
			self.logger.addMessage(apylog.SEVERITY_INFO,'DBF files info read')

			self.logger.addMessage(apylog.SEVERITY_INFO,'Start loading PG worker')
			self.pg_worker = pgworker(self.config_worker.config_data["pg_parameters"]["dbname"],self.config_worker.config_data["pg_parameters"]["user"],self.config_worker.config_data["pg_parameters"]["password"],self.config_worker.config_data["pg_parameters"]["host"],self.config_worker.config_data["pg_parameters"]["port"])
			self.logger.addMessage(apylog.SEVERITY_INFO,'PG worker loaded')
			
		except Exception,err:
			self.logger.addMessage(apylog.SEVERITY_ERROR,err)

	def _doLoad(self):
		while True:
			try:
				c_task = self.upsertQueue.get_nowait()
			except:
				return
			
			tbl = c_task["table"]
			dbf = c_task["file"]

			self.logger.addMessage(apylog.SEVERITY_INFO, "Start work with %s" % tbl)
			pkey_res = self.pg_worker.get_pkey_name(self.config_worker.config_data,tbl)
			if pkey_res["status"] == apylog.SEVERITY_INFO:
				pkey = pkey_res["data"]
				self.logger.addMessage(apylog.SEVERITY_INFO, "%s: start working" % dbf)
				with self.dbf_worker.open_file(dbf) as dbfdata:
					#upsert_result = self.pg_worker.upsert_data(self.config_worker.config_data,tbl,pkey,dbfdata.records)
					upsert_result = self.pg_worker.insert_data(tbl,dbfdata.records)
					self.logger.addMessage(upsert_result["status"],upsert_result["data"])
				self.logger.addMessage(apylog.SEVERITY_INFO, "%s: finished" % dbf)
			else:
				self.logger.addMessage(apylog.SEVERITY_ERROR,pkey_res["data"])
			
	def load(self):
		if len(self.dbf_worker.files_tables.keys()) > 0:
			for tbl in self.dbf_worker.files_tables.keys():
				for dbf in self.dbf_worker.files_tables.get(tbl,[]):
					self.upsertQueue.put({"table": tbl, "file": dbf})

			for _ in xrange(self.config_worker.config_data["threads_count"]):
				thread_ = threading.Thread(target=self._doLoad)
				thread_.start()

			while threading.active_count() > 1:
				time.sleep(1)

	def load_schema(self):
		schema_file = os.path.join(os.path.dirname(__file__),self.config_worker.config_data.get("schema_file",'fias_schema.sql'))
		if os.path.exists(schema_file):
			res_load = self.pg_worker.load_schema(schema_file)
			self.logger.addMessage(res_load["status"],res_load["data"])

	def after_load(self):
		for dtbl in self.config_worker.config_data["fias_dtables"].keys():
			self.logger.addMessage(apylog.SEVERITY_INFO, "Start work with %s" % dtbl)
			pkey_res = self.pg_worker.get_pkey_name(self.config_worker.config_data,dtbl)
			if pkey_res["status"] == apylog.SEVERITY_INFO:
				pkey = pkey_res["data"]
				self.pg_worker.delete_ddata(self.config_worker.config_data,dtbl,pkey,self.config_worker.config_data["fias_dtables"][dtbl])
			else:
				self.logger.addMessage(apylog.SEVERITY_ERROR,pkey_res["data"])

##print dbfreader._type_to_pg(default_config,'D',35,3)
#conf = config(os.path.join(os.path.dirname(__file__),'fiaspgpy_config.json'))
#conf.load_from_file()
#pgw = pgworker(conf.config_data["pg_parameters"]["dbname"],conf.config_data["pg_parameters"]["user"],conf.config_data["pg_parameters"]["password"],conf.config_data["pg_parameters"]["host"])
#dbfr = dbfreader(r'D:\Data\fias_dbf')
#dbfr.read_files(conf.config_data)

#for tbl in conf.config_data.get("fias_table_names",[]):
#	print '%s: %s' % (tbl,pgw.get_pkey_name(conf.config_data,tbl)["data"])

fl = fiasloader(os.path.join(os.path.dirname(__file__),'fiaspgpy_config.json'))
fl.load_schema()
fl.load()
fl.after_load()

print 1