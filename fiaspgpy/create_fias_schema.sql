-- PostgreSQL FIAS schema

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
--COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

SET search_path = public, pg_catalog;
SET default_with_oids = false;

CREATE OR REPLACE FUNCTION public.fias_insert_before()
  RETURNS trigger AS
$BODY$
DECLARE
    p_key_name text;
    attributes text[];
    count_id integer;
BEGIN

    EXECUTE 'select 
        attname from pg_attribute 
        where attrelid in (select conindid from pg_constraint where contype = ''p'' and conrelid = ' || TG_RELID || ');' INTO p_key_name;
        
    EXECUTE 'select array(select attname from pg_attribute where attrelid = ' || TG_RELID || ' and attnum > 0);' into attributes;
    
    EXECUTE 'select count(*) from ' || TG_TABLE_NAME || ' where ' || p_key_name || ' = ($1).' || p_key_name || ';' into count_id using NEW;
    
    IF count_id > 0 THEN
        EXECUTE 'UPDATE ' || TG_TABLE_NAME || ' SET (' || array_to_string(attributes,',') || ') = (($1).*) WHERE ' || p_key_name || ' = ($1).' || p_key_name || ';' USING NEW;
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF; 
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION public.fias_insert_before()
  OWNER TO {0};

DROP TABLE IF EXISTS actstat;
CREATE TABLE actstat
(
  actstatid integer NOT NULL, -- Идентификатор статуса (ключ)
  name character varying(100) NOT NULL, -- Наименование...
  CONSTRAINT actstat_pkey PRIMARY KEY (actstatid)
)
WITH (OIDS=FALSE);

ALTER TABLE actstat OWNER TO {0};

COMMENT ON TABLE actstat IS 'Статус актуальности ФИАС';
COMMENT ON COLUMN actstat.actstatid IS 'Идентификатор статуса (ключ)';
COMMENT ON COLUMN actstat.name IS 'Наименование
0 – Не актуальный
1 – Актуальный (последняя запись по адресному объекту)';

CREATE TRIGGER actstat_before_insert
  BEFORE INSERT
  ON actstat
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS addrobj;
CREATE TABLE addrobj
(
  aoguid character varying(36) NOT NULL, -- Глобальный уникальный идентификатор адресного объекта
  formalname character varying(120), -- Формализованное наименование
  regioncode character varying(2), -- Код региона
  autocode character varying(1), -- Код автономии
  areacode character varying(3), -- Код района
  citycode character varying(3), -- Код города
  ctarcode character varying(3), -- Код внутригородского района
  placecode character varying(3), -- Код населенного пункта
  streetcode character varying(4), -- Код улицы
  extrcode character varying(4), -- Код дополнительного адресообразующего элемента
  sextcode character varying(3), -- Код подчиненного дополнительного адресообразующего элемента
  offname character varying(120), -- Официальное наименование
  postalcode character varying(6), -- Почтовый индекс
  ifnsfl character varying(4), -- Код ИФНС ФЛ
  terrifnsfl character varying(4), -- Код территориального участка ИФНС ФЛ
  ifnsul character varying(4), -- Код ИФНС ЮЛ
  terrifnsul character varying(4), -- Код территориального участка ИФНС ЮЛ
  okato character varying(11), -- ОКАТО
  oktmo character varying(11), -- ОКТМО
  updatedate date, -- Дата  внесения (обновления) записи
  shortname character varying(10), -- Краткое наименование типа объекта
  aolevel integer, -- Уровень адресного объекта
  parentguid character varying(36), -- Идентификатор объекта родительского объекта
  aoid character varying(36), -- Уникальный идентификатор записи. Ключевое поле.
  previd character varying(36), -- Идентификатор записи связывания с предыдушей исторической записью
  nextid character varying(36), -- Идентификатор записи  связывания с последующей исторической записью
  code character varying(17), -- Код адресного объекта одной строкой с признаком актуальности из КЛАДР 4.0.
  plaincode character varying(15), -- Код адресного объекта из КЛАДР 4.0 одной строкой без признака актуальности (последних двух цифр)
  actstatus integer, -- Статус актуальности адресного объекта ФИАС. Актуальный адрес на текущую дату. Обычно последняя запись об адресном объекте.
  centstatus integer, -- Статус центра
  operstatus integer, -- Статус действия над записью – причина появления записи (см. описание таблицы OperationStatus):
  currstatus integer, -- Статус актуальности КЛАДР 4 (последние две цифры в коде)
  startdate date, -- Начало действия записи
  enddate date, -- Окончание действия записи
  normdoc character varying(36), -- Внешний ключ на нормативный документ
  CONSTRAINT addrobj_pkey PRIMARY KEY (aoguid)
)
WITH (OIDS=FALSE);

ALTER TABLE addrobj OWNER TO {0};

COMMENT ON TABLE addrobj IS 'Классификатор адресообразующих элементов';
COMMENT ON COLUMN addrobj.aoguid IS 'Глобальный уникальный идентификатор адресного объекта';
COMMENT ON COLUMN addrobj.formalname IS 'Формализованное наименование';
COMMENT ON COLUMN addrobj.regioncode IS 'Код региона';
COMMENT ON COLUMN addrobj.autocode IS 'Код автономии';
COMMENT ON COLUMN addrobj.areacode IS 'Код района';
COMMENT ON COLUMN addrobj.citycode IS 'Код города';
COMMENT ON COLUMN addrobj.ctarcode IS 'Код внутригородского района';
COMMENT ON COLUMN addrobj.placecode IS 'Код населенного пункта';
COMMENT ON COLUMN addrobj.streetcode IS 'Код улицы';
COMMENT ON COLUMN addrobj.extrcode IS 'Код дополнительного адресообразующего элемента';
COMMENT ON COLUMN addrobj.sextcode IS 'Код подчиненного дополнительного адресообразующего элемента';
COMMENT ON COLUMN addrobj.offname IS 'Официальное наименование';
COMMENT ON COLUMN addrobj.postalcode IS 'Почтовый индекс';
COMMENT ON COLUMN addrobj.ifnsfl IS 'Код ИФНС ФЛ';
COMMENT ON COLUMN addrobj.terrifnsfl IS 'Код территориального участка ИФНС ФЛ';
COMMENT ON COLUMN addrobj.ifnsul IS 'Код ИФНС ЮЛ';
COMMENT ON COLUMN addrobj.terrifnsul IS 'Код территориального участка ИФНС ЮЛ';
COMMENT ON COLUMN addrobj.okato IS 'ОКАТО';
COMMENT ON COLUMN addrobj.oktmo IS 'ОКТМО';
COMMENT ON COLUMN addrobj.updatedate IS 'Дата  внесения (обновления) записи';
COMMENT ON COLUMN addrobj.shortname IS 'Краткое наименование типа объекта';
COMMENT ON COLUMN addrobj.aolevel IS 'Уровень адресного объекта';
COMMENT ON COLUMN addrobj.parentguid IS 'Идентификатор объекта родительского объекта';
COMMENT ON COLUMN addrobj.aoid IS 'Уникальный идентификатор записи. Ключевое поле.';
COMMENT ON COLUMN addrobj.previd IS 'Идентификатор записи связывания с предыдушей исторической записью';
COMMENT ON COLUMN addrobj.nextid IS 'Идентификатор записи  связывания с последующей исторической записью';
COMMENT ON COLUMN addrobj.code IS 'Код адресного объекта одной строкой с признаком актуальности из КЛАДР 4.0.';
COMMENT ON COLUMN addrobj.plaincode IS 'Код адресного объекта из КЛАДР 4.0 одной строкой без признака актуальности (последних двух цифр)';
COMMENT ON COLUMN addrobj.actstatus IS 'Статус актуальности адресного объекта ФИАС. Актуальный адрес на текущую дату. Обычно последняя запись об адресном объекте.';
COMMENT ON COLUMN addrobj.centstatus IS 'Статус центра';
COMMENT ON COLUMN addrobj.operstatus IS 'Статус действия над записью – причина появления записи (см. описание таблицы OperationStatus):';
COMMENT ON COLUMN addrobj.currstatus IS 'Статус актуальности КЛАДР 4 (последние две цифры в коде)';
COMMENT ON COLUMN addrobj.startdate IS 'Начало действия записи';
COMMENT ON COLUMN addrobj.enddate IS 'Окончание действия записи';
COMMENT ON COLUMN addrobj.normdoc IS 'Внешний ключ на нормативный документ';

CREATE TRIGGER addrobj_before_insert
  BEFORE INSERT
  ON addrobj
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS centerst;
CREATE TABLE centerst
(
  centerstid integer NOT NULL, -- Идентификатор статуса (ключ)
  name character varying(100) NOT NULL, -- Наименование
  CONSTRAINT centerst_pkey PRIMARY KEY (centerstid)
)
WITH (OIDS=FALSE);

ALTER TABLE centerst OWNER TO {0};

COMMENT ON TABLE centerst IS 'Статус центра';
COMMENT ON COLUMN centerst.centerstid IS 'Идентификатор статуса (ключ)';
COMMENT ON COLUMN centerst.name IS 'Наименование';

CREATE TRIGGER centerst_before_insert
  BEFORE INSERT
  ON centerst
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS curentst;
CREATE TABLE curentst
(
  curentstid integer NOT NULL, -- Идентификатор статуса (ключ)
  name character varying(100) NOT NULL, -- Наименование ...
  CONSTRAINT curentst_pkey PRIMARY KEY (curentstid)
)
WITH (OIDS=FALSE);

ALTER TABLE curentst OWNER TO {0};

COMMENT ON TABLE curentst IS 'Статус актуальности КЛАДР 4.0';
COMMENT ON COLUMN curentst.curentstid IS 'Идентификатор статуса (ключ)';
COMMENT ON COLUMN curentst.name IS 'Наименование 
(0 - актуальный, 
1-50, 
2-98 – исторический (кроме 51), 
51 - переподчиненный, 
99 - несуществующий)';

CREATE TRIGGER curentst_before_insert
  BEFORE INSERT
  ON curentst
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS daddrobj;
CREATE TABLE daddrobj
(
  aoguid character varying(36) NOT NULL, -- Глобальный уникальный идентификатор адресного объекта
  formalname character varying(120), -- Формализованное наименование
  regioncode character varying(2), -- Код региона
  autocode character varying(1), -- Код автономии
  areacode character varying(3), -- Код района
  citycode character varying(3), -- Код города
  ctarcode character varying(3), -- Код внутригородского района
  placecode character varying(3), -- Код населенного пункта
  streetcode character varying(4), -- Код улицы
  extrcode character varying(4), -- Код дополнительного адресообразующего элемента
  sextcode character varying(3), -- Код подчиненного дополнительного адресообразующего элемента
  offname character varying(120), -- Официальное наименование
  postalcode character varying(6), -- Почтовый индекс
  ifnsfl character varying(4), -- Код ИФНС ФЛ
  terrifnsfl character varying(4), -- Код территориального участка ИФНС ФЛ
  ifnsul character varying(4), -- Код ИФНС ЮЛ
  terrifnsul character varying(4), -- Код территориального участка ИФНС ЮЛ
  okato character varying(11), -- ОКАТО
  oktmo character varying(11), -- ОКТМО
  updatedate date, -- Дата  внесения (обновления) записи
  shortname character varying(10), -- Краткое наименование типа объекта
  aolevel integer, -- Уровень адресного объекта
  parentguid character varying(36), -- Идентификатор объекта родительского объекта
  aoid character varying(36), -- Уникальный идентификатор записи. Ключевое поле.
  previd character varying(36), -- Идентификатор записи связывания с предыдушей исторической записью
  nextid character varying(36), -- Идентификатор записи  связывания с последующей исторической записью
  code character varying(17), -- Код адресного объекта одной строкой с признаком актуальности из КЛАДР 4.0.
  plaincode character varying(15), -- Код адресного объекта из КЛАДР 4.0 одной строкой без признака актуальности (последних двух цифр)
  actstatus integer, -- Статус актуальности адресного объекта ФИАС. Актуальный адрес на текущую дату. Обычно последняя запись об адресном объекте.
  centstatus integer, -- Статус центра
  operstatus integer, -- Статус действия над записью – причина появления записи (см. описание таблицы OperationStatus):
  currstatus integer, -- Статус актуальности КЛАДР 4 (последние две цифры в коде)
  startdate date, -- Начало действия записи
  enddate date, -- Окончание действия записи
  normdoc character varying(36), -- Внешний ключ на нормативный документ
  CONSTRAINT daddrobj_pkey PRIMARY KEY (aoguid)
)
WITH (OIDS=FALSE);

ALTER TABLE daddrobj OWNER TO {0};

COMMENT ON TABLE daddrobj IS 'Классификатор адресообразующих элементов (удалённые объекты)';
COMMENT ON COLUMN daddrobj.aoguid IS 'Глобальный уникальный идентификатор адресного объекта';
COMMENT ON COLUMN daddrobj.formalname IS 'Формализованное наименование';
COMMENT ON COLUMN daddrobj.regioncode IS 'Код региона';
COMMENT ON COLUMN daddrobj.autocode IS 'Код автономии';
COMMENT ON COLUMN daddrobj.areacode IS 'Код района';
COMMENT ON COLUMN daddrobj.citycode IS 'Код города';
COMMENT ON COLUMN daddrobj.ctarcode IS 'Код внутригородского района';
COMMENT ON COLUMN daddrobj.placecode IS 'Код населенного пункта';
COMMENT ON COLUMN daddrobj.streetcode IS 'Код улицы';
COMMENT ON COLUMN daddrobj.extrcode IS 'Код дополнительного адресообразующего элемента';
COMMENT ON COLUMN daddrobj.sextcode IS 'Код подчиненного дополнительного адресообразующего элемента';
COMMENT ON COLUMN daddrobj.offname IS 'Официальное наименование';
COMMENT ON COLUMN daddrobj.postalcode IS 'Почтовый индекс';
COMMENT ON COLUMN daddrobj.ifnsfl IS 'Код ИФНС ФЛ';
COMMENT ON COLUMN daddrobj.terrifnsfl IS 'Код территориального участка ИФНС ФЛ';
COMMENT ON COLUMN daddrobj.ifnsul IS 'Код ИФНС ЮЛ';
COMMENT ON COLUMN daddrobj.terrifnsul IS 'Код территориального участка ИФНС ЮЛ';
COMMENT ON COLUMN daddrobj.okato IS 'ОКАТО';
COMMENT ON COLUMN daddrobj.oktmo IS 'ОКТМО';
COMMENT ON COLUMN daddrobj.updatedate IS 'Дата  внесения (обновления) записи';
COMMENT ON COLUMN daddrobj.shortname IS 'Краткое наименование типа объекта';
COMMENT ON COLUMN daddrobj.aolevel IS 'Уровень адресного объекта';
COMMENT ON COLUMN daddrobj.parentguid IS 'Идентификатор объекта родительского объекта';
COMMENT ON COLUMN daddrobj.aoid IS 'Уникальный идентификатор записи. Ключевое поле.';
COMMENT ON COLUMN daddrobj.previd IS 'Идентификатор записи связывания с предыдушей исторической записью';
COMMENT ON COLUMN daddrobj.nextid IS 'Идентификатор записи  связывания с последующей исторической записью';
COMMENT ON COLUMN daddrobj.code IS 'Код адресного объекта одной строкой с признаком актуальности из КЛАДР 4.0.';
COMMENT ON COLUMN daddrobj.plaincode IS 'Код адресного объекта из КЛАДР 4.0 одной строкой без признака актуальности (последних двух цифр)';
COMMENT ON COLUMN daddrobj.actstatus IS 'Статус актуальности адресного объекта ФИАС. Актуальный адрес на текущую дату. Обычно последняя запись об адресном объекте.';
COMMENT ON COLUMN daddrobj.centstatus IS 'Статус центра';
COMMENT ON COLUMN daddrobj.operstatus IS 'Статус действия над записью – причина появления записи (см. описание таблицы OperationStatus):';
COMMENT ON COLUMN daddrobj.currstatus IS 'Статус актуальности КЛАДР 4 (последние две цифры в коде)';
COMMENT ON COLUMN daddrobj.startdate IS 'Начало действия записи';
COMMENT ON COLUMN daddrobj.enddate IS 'Окончание действия записи';
COMMENT ON COLUMN daddrobj.normdoc IS 'Внешний ключ на нормативный документ';

CREATE TRIGGER daddrobj_before_insert
  BEFORE INSERT
  ON daddrobj
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS dhouse;
CREATE TABLE dhouse
(
  postalcode character varying(6), -- Почтовый индекс
  ifnsfl character varying(4), -- Код ИФНС ФЛ
  terrifnsfl character varying(4), -- Код территориального участка ИФНС ФЛ
  ifnsul character varying(4), -- Код ИФНС ЮЛ
  terrifnsul character varying(4), -- Код территориального участка ИФНС ЮЛ
  okato character varying(11), -- ОКАТО
  oktmo character varying(11), -- ОКTMO
  updatedate date, -- Дата время внесения (обновления) записи
  housenum character varying(20), -- Номер дома
  eststatus integer, -- Признак владения
  buildnum character varying(10), -- Номер корпуса
  strucnum character varying(10), -- Номер строения
  strstatus integer, -- Признак строения
  houseid character varying(36) NOT NULL, -- Уникальный идентификатор записи дома
  houseguid character varying(36), -- Глобальный уникальный идентификатор дома
  aoguid character varying(36), -- Guid записи родительского объекта (улицы, города, населенного пункта и т.п.)
  startdate date, -- Начало действия записи
  enddate date, -- Окончание действия записи
  statstatus integer, -- Состояние дома
  normdoc character varying(36), -- Внешний ключ на нормативный документ
  counter integer, -- Счетчик записей домов для КЛАДР 4
  CONSTRAINT dhouse_pkey PRIMARY KEY (houseid)
)
WITH (OIDS=FALSE);

ALTER TABLE dhouse OWNER TO {0};

COMMENT ON TABLE dhouse IS 'Сведения по номерам домов улиц городов и населенных пунктов, номера земельных участков и т.п (удалённые объекты)';
COMMENT ON COLUMN dhouse.postalcode IS 'Почтовый индекс';
COMMENT ON COLUMN dhouse.ifnsfl IS 'Код ИФНС ФЛ';
COMMENT ON COLUMN dhouse.terrifnsfl IS 'Код территориального участка ИФНС ФЛ';
COMMENT ON COLUMN dhouse.ifnsul IS 'Код ИФНС ЮЛ';
COMMENT ON COLUMN dhouse.terrifnsul IS 'Код территориального участка ИФНС ЮЛ';
COMMENT ON COLUMN dhouse.okato IS 'ОКАТО';
COMMENT ON COLUMN dhouse.oktmo IS 'ОКTMO';
COMMENT ON COLUMN dhouse.updatedate IS 'Дата время внесения (обновления) записи';
COMMENT ON COLUMN dhouse.housenum IS 'Номер дома';
COMMENT ON COLUMN dhouse.eststatus IS 'Признак владения';
COMMENT ON COLUMN dhouse.buildnum IS 'Номер корпуса';
COMMENT ON COLUMN dhouse.strucnum IS 'Номер строения';
COMMENT ON COLUMN dhouse.strstatus IS 'Признак строения';
COMMENT ON COLUMN dhouse.houseid IS 'Уникальный идентификатор записи дома';
COMMENT ON COLUMN dhouse.houseguid IS 'Глобальный уникальный идентификатор дома';
COMMENT ON COLUMN dhouse.aoguid IS 'Guid записи родительского объекта (улицы, города, населенного пункта и т.п.)';
COMMENT ON COLUMN dhouse.startdate IS 'Начало действия записи';
COMMENT ON COLUMN dhouse.enddate IS 'Окончание действия записи';
COMMENT ON COLUMN dhouse.statstatus IS 'Состояние дома';
COMMENT ON COLUMN dhouse.normdoc IS 'Внешний ключ на нормативный документ';
COMMENT ON COLUMN dhouse.counter IS 'Счетчик записей домов для КЛАДР 4';

CREATE TRIGGER dhouse_before_insert
  BEFORE INSERT
  ON dhouse
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS dhousint;
CREATE TABLE dhousint
(
  postalcode character varying(6), -- Почтовый индекс
  ifnsfl character varying(4), -- Код ИФНС ФЛ
  terrifnsfl character varying(4), -- Код территориального участка ИФНС ФЛ
  ifnsul character varying(4), -- Код ИФНС ЮЛ
  terrifnsul character varying(4), -- Код территориального участка ИФНС ЮЛ
  okato character varying(11), -- ОКАТО
  oktmo character varying(11), -- ОКТМО
  updatedate date, -- Дата  внесения (обновления) записи
  intstart integer, -- Значение начала интервала
  intend integer, -- Значение окончания интервала
  houseintid character varying(36) NOT NULL, -- Идентификатор записи интервала домов
  intguid character varying(36), -- Глобальный уникальный идентификатор интервала домов
  aoguid character varying(36), -- Идентификатор объекта родительского объекта (улицы, города, населенного пункта и т.п.)
  startdate date, -- Начало действия записи
  enddate date, -- Окончание действия записи
  intstatus integer, -- Статус интервала (обычный, четный, нечетный)
  normdoc character varying(36), -- Внешний ключ на нормативный документ
  counter integer, -- Счетчик записей домов для КЛАДР 4
  CONSTRAINT dhousint_pkey PRIMARY KEY (houseintid)
)
WITH (OIDS=FALSE);

ALTER TABLE dhousint OWNER TO {0};

COMMENT ON TABLE dhousint IS 'Интервалы домов (удалённые объекты)';

COMMENT ON COLUMN dhousint.postalcode IS 'Почтовый индекс';
COMMENT ON COLUMN dhousint.ifnsfl IS 'Код ИФНС ФЛ';
COMMENT ON COLUMN dhousint.terrifnsfl IS 'Код территориального участка ИФНС ФЛ';
COMMENT ON COLUMN dhousint.ifnsul IS 'Код ИФНС ЮЛ';
COMMENT ON COLUMN dhousint.terrifnsul IS 'Код территориального участка ИФНС ЮЛ';
COMMENT ON COLUMN dhousint.okato IS 'ОКАТО';
COMMENT ON COLUMN dhousint.oktmo IS 'ОКТМО';
COMMENT ON COLUMN dhousint.updatedate IS 'Дата  внесения (обновления) записи';
COMMENT ON COLUMN dhousint.intstart IS 'Значение начала интервала';
COMMENT ON COLUMN dhousint.intend IS 'Значение окончания интервала';
COMMENT ON COLUMN dhousint.houseintid IS 'Идентификатор записи интервала домов';
COMMENT ON COLUMN dhousint.intguid IS 'Глобальный уникальный идентификатор интервала домов';
COMMENT ON COLUMN dhousint.aoguid IS 'Идентификатор объекта родительского объекта (улицы, города, населенного пункта и т.п.)';
COMMENT ON COLUMN dhousint.startdate IS 'Начало действия записи';
COMMENT ON COLUMN dhousint.enddate IS 'Окончание действия записи';
COMMENT ON COLUMN dhousint.intstatus IS 'Статус интервала (обычный, четный, нечетный)';
COMMENT ON COLUMN dhousint.normdoc IS 'Внешний ключ на нормативный документ';
COMMENT ON COLUMN dhousint.counter IS 'Счетчик записей домов для КЛАДР 4';

CREATE TRIGGER dhousint_before_insert
  BEFORE INSERT
  ON dhousint
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS dlandmark;
CREATE TABLE dlandmark
(
  location character varying(500), -- Месторасположение ориентира
  postalcode character varying(6), -- Почтовый индекс
  ifnsfl character varying(4), -- Код ИФНС ФЛ
  terrifnsfl character varying(4), -- Код территориального участка ИФНС ФЛ
  infsul character varying(4), -- Код ИФНС ЮЛ
  terrifnsul character varying(4), -- Код территориального участка ИФНС ЮЛ
  okato character varying(11), -- ОКАТО
  oktmo character varying(11), -- ОКТМО
  updatedate date, -- Дата внесения (обновления) записи
  landid character varying(36) NOT NULL, -- Уникальный идентификатор записи ориентира
  landguid character varying(36), -- Глобальный уникальный идентификатор ориентира
  aoguid character varying(36), -- Уникальный идентификатор родительского объекта (улицы, города, населенного пункта и т.п.)
  startdate date, -- Начало действия записи
  enddate date, -- Окончание действия записи
  CONSTRAINT dlandmark_pkey PRIMARY KEY (landid)
)
WITH (OIDS=FALSE);

ALTER TABLE dlandmark OWNER TO {0};

COMMENT ON TABLE dlandmark IS 'Описание мест расположения  имущественных объектов (удалённые объекты)';
COMMENT ON COLUMN dlandmark.location IS 'Месторасположение ориентира';
COMMENT ON COLUMN dlandmark.postalcode IS 'Почтовый индекс';
COMMENT ON COLUMN dlandmark.ifnsfl IS 'Код ИФНС ФЛ';
COMMENT ON COLUMN dlandmark.terrifnsfl IS 'Код территориального участка ИФНС ФЛ';
COMMENT ON COLUMN dlandmark.infsul IS 'Код ИФНС ЮЛ';
COMMENT ON COLUMN dlandmark.terrifnsul IS 'Код территориального участка ИФНС ЮЛ';
COMMENT ON COLUMN dlandmark.okato IS 'ОКАТО';
COMMENT ON COLUMN dlandmark.oktmo IS 'ОКТМО';
COMMENT ON COLUMN dlandmark.updatedate IS 'Дата внесения (обновления) записи';
COMMENT ON COLUMN dlandmark.landid IS 'Уникальный идентификатор записи ориентира';
COMMENT ON COLUMN dlandmark.landguid IS 'Глобальный уникальный идентификатор ориентира';
COMMENT ON COLUMN dlandmark.aoguid IS 'Уникальный идентификатор родительского объекта (улицы, города, населенного пункта и т.п.)';
COMMENT ON COLUMN dlandmark.startdate IS 'Начало действия записи';
COMMENT ON COLUMN dlandmark.enddate IS 'Окончание действия записи';

CREATE TRIGGER dlandmark_before_insert
  BEFORE INSERT
  ON dlandmark
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS dnordoc;
CREATE TABLE dnordoc
(
  normdocid character varying(36) NOT NULL, -- Идентификатор нормативного документа
  docname text, -- Наименование документа
  docdate date, -- Дата документа
  docnum character varying(20), -- Номер документа
  doctype integer, -- Тип документа
  docimgid integer, -- Идентификатор образа (внешний ключ)
  CONSTRAINT dnordoc_pkey PRIMARY KEY (normdocid)
)
WITH (OIDS=FALSE);

ALTER TABLE dnordoc OWNER TO {0};

COMMENT ON TABLE dnordoc IS 'Сведения по нормативному документу, являющемуся основанием присвоения адресному элементу наименования (удалённые объекты)';
COMMENT ON COLUMN dnordoc.normdocid IS 'Идентификатор нормативного документа';
COMMENT ON COLUMN dnordoc.docname IS 'Наименование документа';
COMMENT ON COLUMN dnordoc.docdate IS 'Дата документа';
COMMENT ON COLUMN dnordoc.docnum IS 'Номер документа';
COMMENT ON COLUMN dnordoc.doctype IS 'Тип документа';
COMMENT ON COLUMN dnordoc.docimgid IS 'Идентификатор образа (внешний ключ)';

CREATE TRIGGER dnordoc_before_insert
  BEFORE INSERT
  ON dnordoc
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS eststat;
CREATE TABLE eststat
(
  eststatid integer NOT NULL, -- Идентификатор статуса (ключ)
  name character varying(20) NOT NULL, -- Наименование
  shortname character varying(20), -- Краткое наименование
  CONSTRAINT eststat_pkey PRIMARY KEY (eststatid)
)
WITH (OIDS=FALSE);

ALTER TABLE eststat OWNER TO {0};

COMMENT ON TABLE eststat IS 'Признак владения';
COMMENT ON COLUMN eststat.eststatid IS 'Идентификатор статуса (ключ)';
COMMENT ON COLUMN eststat.name IS 'Наименование';
COMMENT ON COLUMN eststat.shortname IS 'Краткое наименование';

CREATE TRIGGER eststat_before_insert
  BEFORE INSERT
  ON eststat
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS house;
CREATE TABLE house
(
  postalcode character varying(6), -- Почтовый индекс
  ifnsfl character varying(4), -- Код ИФНС ФЛ
  terrifnsfl character varying(4), -- Код территориального участка ИФНС ФЛ
  ifnsul character varying(4), -- Код ИФНС ЮЛ
  terrifnsul character varying(4), -- Код территориального участка ИФНС ЮЛ
  okato character varying(11), -- ОКАТО
  oktmo character varying(11), -- ОКTMO
  updatedate date, -- Дата время внесения (обновления) записи
  housenum character varying(20), -- Номер дома
  eststatus integer, -- Признак владения
  buildnum character varying(10), -- Номер корпуса
  strucnum character varying(10), -- Номер строения
  strstatus integer, -- Признак строения
  houseid character varying(36) NOT NULL, -- Уникальный идентификатор записи дома
  houseguid character varying(36), -- Глобальный уникальный идентификатор дома
  aoguid character varying(36), -- Guid записи родительского объекта (улицы, города, населенного пункта и т.п.)
  startdate date, -- Начало действия записи
  enddate date, -- Окончание действия записи
  statstatus integer, -- Состояние дома
  normdoc character varying(36), -- Внешний ключ на нормативный документ
  counter integer, -- Счетчик записей домов для КЛАДР 4
  CONSTRAINT house_pkey PRIMARY KEY (houseid)
)
WITH (OIDS=FALSE);

ALTER TABLE house OWNER TO {0};

COMMENT ON TABLE house IS 'Сведения по номерам домов улиц городов и населенных пунктов, номера земельных участков и т.п';
COMMENT ON COLUMN house.postalcode IS 'Почтовый индекс';
COMMENT ON COLUMN house.ifnsfl IS 'Код ИФНС ФЛ';
COMMENT ON COLUMN house.terrifnsfl IS 'Код территориального участка ИФНС ФЛ';
COMMENT ON COLUMN house.ifnsul IS 'Код ИФНС ЮЛ';
COMMENT ON COLUMN house.terrifnsul IS 'Код территориального участка ИФНС ЮЛ';
COMMENT ON COLUMN house.okato IS 'ОКАТО';
COMMENT ON COLUMN house.oktmo IS 'ОКTMO';
COMMENT ON COLUMN house.updatedate IS 'Дата время внесения (обновления) записи';
COMMENT ON COLUMN house.housenum IS 'Номер дома';
COMMENT ON COLUMN house.eststatus IS 'Признак владения';
COMMENT ON COLUMN house.buildnum IS 'Номер корпуса';
COMMENT ON COLUMN house.strucnum IS 'Номер строения';
COMMENT ON COLUMN house.strstatus IS 'Признак строения';
COMMENT ON COLUMN house.houseid IS 'Уникальный идентификатор записи дома';
COMMENT ON COLUMN house.houseguid IS 'Глобальный уникальный идентификатор дома';
COMMENT ON COLUMN house.aoguid IS 'Guid записи родительского объекта (улицы, города, населенного пункта и т.п.)';
COMMENT ON COLUMN house.startdate IS 'Начало действия записи';
COMMENT ON COLUMN house.enddate IS 'Окончание действия записи';
COMMENT ON COLUMN house.statstatus IS 'Состояние дома';
COMMENT ON COLUMN house.normdoc IS 'Внешний ключ на нормативный документ';
COMMENT ON COLUMN house.counter IS 'Счетчик записей домов для КЛАДР 4';

CREATE TRIGGER house_before_insert
  BEFORE INSERT
  ON house
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS houseint;
CREATE TABLE houseint
(
  postalcode character varying(6), -- Почтовый индекс
  ifnsfl character varying(4), -- Код ИФНС ФЛ
  terrifnsfl character varying(4), -- Код территориального участка ИФНС ФЛ
  ifnsul character varying(4), -- Код ИФНС ЮЛ
  terrifnsul character varying(4), -- Код территориального участка ИФНС ЮЛ
  okato character varying(11), -- ОКАТО
  oktmo character varying(11), -- ОКТМО
  updatedate date, -- Дата  внесения (обновления) записи
  intstart integer, -- Значение начала интервала
  intend integer, -- Значение окончания интервала
  houseintid character varying(36) NOT NULL, -- Идентификатор записи интервала домов
  intguid character varying(36), -- Глобальный уникальный идентификатор интервала домов
  aoguid character varying(36), -- Идентификатор объекта родительского объекта (улицы, города, населенного пункта и т.п.)
  startdate date, -- Начало действия записи
  enddate date, -- Окончание действия записи
  intstatus integer, -- Статус интервала (обычный, четный, нечетный)
  normdoc character varying(36), -- Внешний ключ на нормативный документ
  counter integer, -- Счетчик записей домов для КЛАДР 4
  CONSTRAINT houseint_pkey PRIMARY KEY (houseintid)
)
WITH (OIDS=FALSE);

ALTER TABLE houseint OWNER TO {0};

COMMENT ON TABLE houseint IS 'Интервалы домов';
COMMENT ON COLUMN houseint.postalcode IS 'Почтовый индекс';
COMMENT ON COLUMN houseint.ifnsfl IS 'Код ИФНС ФЛ';
COMMENT ON COLUMN houseint.terrifnsfl IS 'Код территориального участка ИФНС ФЛ';
COMMENT ON COLUMN houseint.ifnsul IS 'Код ИФНС ЮЛ';
COMMENT ON COLUMN houseint.terrifnsul IS 'Код территориального участка ИФНС ЮЛ';
COMMENT ON COLUMN houseint.okato IS 'ОКАТО';
COMMENT ON COLUMN houseint.oktmo IS 'ОКТМО';
COMMENT ON COLUMN houseint.updatedate IS 'Дата  внесения (обновления) записи';
COMMENT ON COLUMN houseint.intstart IS 'Значение начала интервала';
COMMENT ON COLUMN houseint.intend IS 'Значение окончания интервала';
COMMENT ON COLUMN houseint.houseintid IS 'Идентификатор записи интервала домов';
COMMENT ON COLUMN houseint.intguid IS 'Глобальный уникальный идентификатор интервала домов';
COMMENT ON COLUMN houseint.aoguid IS 'Идентификатор объекта родительского объекта (улицы, города, населенного пункта и т.п.)';
COMMENT ON COLUMN houseint.startdate IS 'Начало действия записи';
COMMENT ON COLUMN houseint.enddate IS 'Окончание действия записи';
COMMENT ON COLUMN houseint.intstatus IS 'Статус интервала (обычный, четный, нечетный)';
COMMENT ON COLUMN houseint.normdoc IS 'Внешний ключ на нормативный документ';
COMMENT ON COLUMN houseint.counter IS 'Счетчик записей домов для КЛАДР 4';

CREATE TRIGGER houseint_before_insert
  BEFORE INSERT
  ON houseint
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS hststat;
CREATE TABLE hststat
(
  housestid integer NOT NULL, -- Идентификатор статуса (ключ)
  name character varying(60), -- Наименование
  CONSTRAINT hststat_pkey PRIMARY KEY (housestid)
)
WITH (OIDS=FALSE);

ALTER TABLE hststat OWNER TO {0};

COMMENT ON TABLE hststat IS 'Статус состояния объектов недвижимости';
COMMENT ON COLUMN hststat.housestid IS 'Идентификатор статуса (ключ)';
COMMENT ON COLUMN hststat.name IS 'Наименование';

CREATE TRIGGER hststat_before_insert
  BEFORE INSERT
  ON hststat
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS intvstat;
CREATE TABLE intvstat
(
  intvstatid integer NOT NULL, -- Идентификатор статуса (ключ)
  name character varying(60) NOT NULL, -- Наименование (обычный, четный, нечетный)
  CONSTRAINT intvstat_pkey PRIMARY KEY (intvstatid)
)
WITH (OIDS=FALSE);

ALTER TABLE intvstat OWNER TO {0};

COMMENT ON TABLE intvstat IS 'Статус интервала домов';
COMMENT ON COLUMN intvstat.intvstatid IS 'Идентификатор статуса (ключ)';
COMMENT ON COLUMN intvstat.name IS 'Наименование (обычный, четный, нечетный)';

CREATE TRIGGER intvstat_before_insert
  BEFORE INSERT
  ON intvstat
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS landmark;
CREATE TABLE landmark
(
  location character varying(500), -- Месторасположение ориентира
  postalcode character varying(6), -- Почтовый индекс
  ifnsfl character varying(4), -- Код ИФНС ФЛ
  terrifnsfl character varying(4), -- Код территориального участка ИФНС ФЛ
  infsul character varying(4), -- Код ИФНС ЮЛ
  terrifnsul character varying(4), -- Код территориального участка ИФНС ЮЛ
  okato character varying(11), -- ОКАТО
  oktmo character varying(11), -- ОКТМО
  updatedate date, -- Дата внесения (обновления) записи
  landid character varying(36) NOT NULL, -- Уникальный идентификатор записи ориентира
  landguid character varying(36), -- Глобальный уникальный идентификатор ориентира
  aoguid character varying(36), -- Уникальный идентификатор родительского объекта (улицы, города, населенного пункта и т.п.)
  startdate date, -- Начало действия записи
  enddate date, -- Окончание действия записи
  CONSTRAINT landmark_pkey PRIMARY KEY (landid)
)
WITH (OIDS=FALSE);

ALTER TABLE landmark OWNER TO {0};

COMMENT ON TABLE landmark IS 'Описание мест расположения  имущественных объектов';
COMMENT ON COLUMN landmark.location IS 'Месторасположение ориентира';
COMMENT ON COLUMN landmark.postalcode IS 'Почтовый индекс';
COMMENT ON COLUMN landmark.ifnsfl IS 'Код ИФНС ФЛ';
COMMENT ON COLUMN landmark.terrifnsfl IS 'Код территориального участка ИФНС ФЛ';
COMMENT ON COLUMN landmark.infsul IS 'Код ИФНС ЮЛ';
COMMENT ON COLUMN landmark.terrifnsul IS 'Код территориального участка ИФНС ЮЛ';
COMMENT ON COLUMN landmark.okato IS 'ОКАТО';
COMMENT ON COLUMN landmark.oktmo IS 'ОКТМО';
COMMENT ON COLUMN landmark.updatedate IS 'Дата внесения (обновления) записи';
COMMENT ON COLUMN landmark.landid IS 'Уникальный идентификатор записи ориентира';
COMMENT ON COLUMN landmark.landguid IS 'Глобальный уникальный идентификатор ориентира';
COMMENT ON COLUMN landmark.aoguid IS 'Уникальный идентификатор родительского объекта (улицы, города, населенного пункта и т.п.)';
COMMENT ON COLUMN landmark.startdate IS 'Начало действия записи';
COMMENT ON COLUMN landmark.enddate IS 'Окончание действия записи';

CREATE TRIGGER landmark_before_insert
  BEFORE INSERT
  ON landmark
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS nordoc;
CREATE TABLE nordoc
(
  normdocid character varying(36) NOT NULL, -- Идентификатор нормативного документа
  docname text, -- Наименование документа
  docdate date, -- Дата документа
  docnum character varying(20), -- Номер документа
  doctype integer, -- Тип документа
  docimgid text, -- Идентификатор образа (внешний ключ)
  CONSTRAINT nordoc_pkey PRIMARY KEY (normdocid)
)
WITH (OIDS=FALSE);

ALTER TABLE nordoc OWNER TO {0};

COMMENT ON TABLE nordoc IS 'Сведения по нормативному документу, являющемуся основанием присвоения адресному элементу наименования';
COMMENT ON COLUMN nordoc.normdocid IS 'Идентификатор нормативного документа';
COMMENT ON COLUMN nordoc.docname IS 'Наименование документа';
COMMENT ON COLUMN nordoc.docdate IS 'Дата документа';
COMMENT ON COLUMN nordoc.docnum IS 'Номер документа';
COMMENT ON COLUMN nordoc.doctype IS 'Тип документа';
COMMENT ON COLUMN nordoc.docimgid IS 'Идентификатор образа (внешний ключ)';

CREATE TRIGGER nordoc_before_insert
  BEFORE INSERT
  ON nordoc
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS operstat;
CREATE TABLE operstat
(
  operstatid integer NOT NULL, -- Идентификатор статуса (ключ)
  name character varying(100) NOT NULL, -- Наименование...
  CONSTRAINT operstat_pkey PRIMARY KEY (operstatid)
)
WITH (OIDS=FALSE);

ALTER TABLE operstat OWNER TO {0};

COMMENT ON TABLE operstat IS 'Статус действия';
COMMENT ON COLUMN operstat.operstatid IS 'Идентификатор статуса (ключ)';
COMMENT ON COLUMN operstat.name IS 'Наименование
01 – Инициация;
10 – Добавление;
20 – Изменение;
21 – Групповое изменение;
30 – Удаление;
31 - Удаление вследствие удаления вышестоящего объекта;
40 – Присоединение адресного объекта (слияние);
41 – Переподчинение вследствие слияния вышестоящего объекта;
42 - Прекращение существования вследствие присоединения к другому адресному объекту;
43 - Создание нового адресного объекта в результате слияния адресных объектов;
50 – Переподчинение;
51 – Переподчинение вследствие переподчинения вышестоящего объекта;
60 – Прекращение существования вследствие дробления;
61 – Создание нового адресного объекта в результате дробления;
70 – Восстановление прекратившего существование объекта';

CREATE TRIGGER operstat_before_insert
  BEFORE INSERT
  ON operstat
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS socrbase;
CREATE TABLE socrbase
(
  level integer NOT NULL, -- Уровень адресного объекта
  scname character varying(10), -- Краткое наименование типа объекта
  socrname character varying(50), -- Полное наименование типа объекта
  kod_t_st character varying(4) NOT NULL, -- Ключевое поле
  CONSTRAINT socrbase_pkey PRIMARY KEY (kod_t_st)
)
WITH (OIDS=FALSE);

ALTER TABLE socrbase OWNER TO {0};

COMMENT ON TABLE socrbase IS 'Типы адресных объектов';
COMMENT ON COLUMN socrbase.level IS 'Уровень адресного объекта';
COMMENT ON COLUMN socrbase.scname IS 'Краткое наименование типа объекта';
COMMENT ON COLUMN socrbase.socrname IS 'Полное наименование типа объекта';
COMMENT ON COLUMN socrbase.kod_t_st IS 'Ключевое поле';

CREATE TRIGGER socrbase_before_insert
  BEFORE INSERT
  ON socrbase
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();

DROP TABLE IF EXISTS strstat;
CREATE TABLE strstat
(
  strstatid integer NOT NULL, -- Идентификатор статуса (ключ)
  name character varying(20) NOT NULL, -- Наименование
  shortname character varying(20), -- Краткое наименование
  CONSTRAINT strstat_pkey PRIMARY KEY (strstatid)
)
WITH (OIDS=FALSE);

ALTER TABLE strstat OWNER TO {0};

COMMENT ON TABLE strstat IS 'Признак владения';
COMMENT ON COLUMN strstat.strstatid IS 'Идентификатор статуса (ключ)';
COMMENT ON COLUMN strstat.name IS 'Наименование';
COMMENT ON COLUMN strstat.shortname IS 'Краткое наименование';

CREATE TRIGGER strstat_before_insert
  BEFORE INSERT
  ON strstat
  FOR EACH ROW
  EXECUTE PROCEDURE fias_insert_before();
