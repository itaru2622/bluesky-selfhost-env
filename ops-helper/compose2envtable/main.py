#!/usr/bin/env python3

'''
make table of envs x containers x its value from docker-composer.yaml

required 3rd party packages
pydantic v2
pandas
openpyxl (optional, output to excel)
'''

from   pydantic import BaseModel, ConfigDict, computed_field
import pandas   as pd

from   collections import Counter
from   typing      import Self, Any
import yaml
import json
import sys
import os
import argparse

class ValContainer(BaseModel):
     '''
     data model to describe value on each container.

     Attributes:
       - val (str): value of environment.
       - container (str): name of service in docker-compose
     '''

     val: str
     container: str

class EnvVal(BaseModel):
     '''
     data model to describe env name and its value for all containers(services) in docker-compose.

     Attributes:
       - env (str): environment name
       - value (list[ValContainer]): pairs of {val, container};  length>1 when the same env is used in multiple containers.
       - values_assigned   (list[str]; by computing): unique assigned values in common ordered for the above value.
       - values_mostCommon (str; by computing): most common value among the above.
       - and others (extra properties==allowed).
     '''
     model_config = ConfigDict(extra='allow')

     env : str
     value  : list['ValContainer'] = []
     composerOnly_: str = None
     __statisticsFields__: list[str] = ['composerOnly_', 'mostCommon_', 'assigned_' ] # hidden class params

     @computed_field(return_type=list[str])
     @property
     def assigned_(self) -> str:
          '''compute and return unique assigned values in common order from current value instances, when needed.
             NOTE: THIS ATTRIBUTE DOES NOT RETURN MOST-COMMON-VALUE, but seconds and beyonds.
          '''
          if self.value in [ None, [] ]:
               return None

          lv = [ itr.val for itr in self.value ]       # get list of val
          count = Counter(lv)
          rtn  = [ v for v, _ in count.most_common() ] # get unique and common ordered list of value.

          if len(rtn)<2:
               return None
          return rtn[1:]  # returns values other than most-common-value.

     @computed_field(return_type=str)
     @property
     def mostCommon_(self) -> str:
          '''compute and return most common value from current value instances, when needed.
          '''
          if self.value in [ None, [] ]:
               return None

          # rtn = self.values_asssigned[0]
          lv = [ itr.val for itr in self.value ]
          count = Counter(lv)
          rtn = count.most_common(1)[0][0]
          return rtn

     def add(self, v: str, c: str) -> Self:
          '''helper function to add instance into value.

          Args:
            - v (str): value
            - c (str): container
          '''
          self.value.append(ValContainer(val=v, container=c))
          return self


def readEnvList(path: str) -> set[str]:
     '''
     get list of env names from path.

     Args:
       - path (str): input file path
     Returns:
       - set[str]:  env list.
     '''

     with open(path, 'r') as fp:
          cont = fp.read()
     if cont in [ None, '' ]:
          return set([])
     return set( cont.split())


def readYaml(path: str) -> dict:
     '''
     get content of yaml in dict.

     Args:
       - path (str): input file path
     Returns:
       - dict:  content of yaml.
     '''

     fp = sys.stdin
     if path not in ['-', '/dev/stdin']:
        fp = open(path, 'r')

     cont = fp.read()
     d = yaml.load(cont, Loader=yaml.Loader)
     fp.close()
     return d


def dumpYaml(d: dict):
    yaml.dump(d, Dumper=yaml.Dumper)


def pickEnvsFromComposer(d: dict, limits: list[str]=None, excludes: list[str]=None) -> dict:
     '''
     pick services[some].environment from content of docker-compose.yaml

     Args:
       - d (dict): content of docker-compose.yaml
       - limits (list[str]):   names to want.
       - excludes (list[str]): names NOT to want.

     Returns:
       - dict:  partial dict of input
     '''

     # phase1) pick just services parts.
     d = d.get('services')

     # phase2) pick environment parts from each service.
     for k, d2 in d.items():
         d2 = d2.get('environment')
         d[k] = d2

     ls = set(d.keys())      # make candidates from given dict.keys ( i.e. services).
     # phase3-1) excludes specified services
     if excludes not in [ None, []]:
          ls = ls.difference(excludes)
     # phase3-2) limts to specified services
     if limits not in [None, []]:
          ls = ls.intersection(limits)

     # phase4) finally, make partial dict containing just specified services.
     rtn = { k: d[k] for k in ls  if k in d }
     return rtn


def reshapeEnvsInComposer(d: dict ) -> dict:
     '''
     reshape services[].environment from list style to dict style.

     Args:
       - d (dict): partial content of docker-compose.yaml

     Returns:
       - dict:     reshaped dict.
     '''

     for s, tmp in list(d.items()):
         if isinstance(tmp, dict):
             continue
         if tmp is None:
             del d[s]
             continue
         # tmp is not dict => reshape to dict from list of var=val style
         envs: dict = {}
         for env in tmp:
             k, v = env.split('=',1) # split just by first '=', but not others ('=' in val).
             envs[k]=v
         d[s] = envs
     return d


def groupbyEnv(d: dict) -> dict:
     '''
     groupBy env-name of input dict, with EnvVal and ValContainer

     Args:
       - d (dict): dict based docker-compose.yaml

     Returns:
       - dict[str, EnvVal]: result of groupBy aggregation.
     '''

     rtn: dict = {}

     for svc, envs in d.items():
        for key, val in envs.items():
            if key not in rtn:
                rtn[key] = EnvVal(env=key).add(val,svc)
            else:
                rtn[key].add(val,svc)

     return rtn


def fillCommonVal(d: dict[str, EnvVal], commonValField: str='value_mostCommon') -> dict[str, EnvVal]:
     '''
     find most common value from list of d.values[].val and assign it to commonValField of d
     '''
     for ev in d.values():
          cv = ev.mostCommonValue
          lv = [ itr.val for itr in ev.value ]
          count = Counter(lv)
          cv = count.most_common(1)[0][0]
          setattr(ev, commonValField, cv)
     return d

def update4ComposerOnly(rows: set[str], gd: dict[str, EnvVal], mark: str='Y') -> tuple:

     '''
     mark envs which exist in gd.EnvVal but not rows and returns new rows after adding them.

     Args:
       - rows (set[str]): current candidates for rows, loaded from external list.
       - gd   (dict[str,EnvVal]): target data to mark
       - mark (str)   : marker to envs matched by condition.

     Returns:
       - list[str]:  new list of rows.
       - gd (dict[str,EnvVal]): data with mark
     '''

     envNamesInComposer = set( gd.keys() )
     composerOnly =envNamesInComposer.difference(rows)              # find envs which exist in composer but not in external env lists(rows).
     for k in composerOnly:
          ev = gd.get(k)
          ev.composerOnly_ = mark

     newrows = sorted(rows | composerOnly, key=lambda s: s.lower()) #   sort with ignore-cases
     return newrows, gd


def mkTable(rows: list[str],  cols:list[str], lev: list[EnvVal], initial_val:Any=None, extraFields: list[str]=[]) -> pd.DataFrame:
     '''
     make table as pandas DataFrame from row, cols, and EnvVal.

     Args:
       - rows (list[str]): table schema for rows
       - cols (list[str]): table schema for cols
       - lev  (list[EnvVal]): data to make table.
       - initial_val(Any): initial value for all cells
       - extraFields (list[str]): extra properties to fill from EnvVal into table.

     Returns:
       - panda Dataframe:  envs x containers with values in table.
     '''
     
     # make dataframe with schema.
     df = pd.DataFrame(data=initial_val, index=rows, columns=cols)
     df = df.rename_axis(index='env', columns='containers')

     # fill data into each table cell.
     for ev in lev:
          r = ev.env         # row for cell
          for p in extraFields:                 # get and fill extra properties from EnvVal to table.
              df.at[r , p ] = getattr(ev, p )

          for vc in ev.value:
            c = vc.container # col for cell
            v = vc.val       # celldata
            df.at[r, c] = v  # fill v into corresponding cell.
     return df

def writeDF(df: pd.DataFrame, path: str, writer:str=None, **kwargs):

     '''
     write table(DataFrame) to file
     Args:
       - df (pd.DataFrame): data for output
       - path (str): file name to store data
       - writer (str): function name of writer to output data
       - kwargs (dict): other extra options of panda dataframe writer.
     '''

     fn = df.to_csv # default function for writer
     
     if writer is not None: # when writer is specified, use it.
          fn = getattr(df, writer)
     elif any( path.endswith(suffix) for suffix in [ '.xlsx', '.xls']):
          fn = df.to_excel
     elif any( path.endswith(suffix) for suffix in [ '.json', '.js']):
          fn = df.to_json
     elif any( path.endswith(suffix) for suffix in [ '.md', '.markdown']):
          fn = df.to_markdown

     if path in ['-']:
          path = sys.stdout

     try:
          fn(path, **kwargs) # save data into file with corresponding writer function of DataFrame.
     except BrokenPipeError:
          pass


if __name__ == '__main__':

    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input',    type=str,   default='-',         help='path of docker-composer.yaml to parse(default: stdin)')
    parser.add_argument('-e', '--excludes', nargs='+',  default=None,        help='services NOT to parse; optional (default: no-exclusion; i.e: all)')
    parser.add_argument('-s', '--includes', nargs='+',  default=None,        help='limit services to parse; optional (default: none; i.e: all)')
    parser.add_argument('-l', '--envlist',  type=str,   default=os.devnull,  help='list of env names to use table schema; optional(default: /dev/null,  to skip loading list)')
    parser.add_argument('-o', '--output',   type=str,   default='-',         help='output file path (*.xlsx, *.json, *.csv etc), to output result (default: stdout)')
    parser.add_argument('-w', '--writer',   type=str,   default=None,        help='enforce writer for output dataframe into file(default: None)')
    parser.add_argument('--no-statistics',  action='store_true',             help='flag to output statistic values on env into table or not( default:False, i.e: include statistics)')
    parser.add_argument('-t', '--transpose',   action='store_true',          help='transpose table(swap rows<=>cols) just before output(default: False)')


    opts = parser.parse_args()

    d = readYaml(opts.input)                                        # read docker-compose yaml file into d(dict)
    d = pickEnvsFromComposer(d, opts.includes, opts.excludes)       # pick just .services[<selected>].environment
    cols = sorted(d.keys(), key=lambda s: s.lower())                # cols <= services in composer, to use table schema.

    d = reshapeEnvsInComposer(d)                                    # change envs style in composer (list[env=val) => dict[k:env, v:val] ) for easy parse.
    gd = groupbyEnv(d)                                              # apply groupby env to d, and get gd; i.e. dict[ k:env,  v:EnvVal[ env: env, value: list[ ValContainer[ val=v, container=c]]]]
    envNamesInComposer = set(gd.keys())                             # get env names in composer

    rows = readEnvList(opts.envlist)                                # make rows(envs) for table schema based on external list.
    rows, gd = update4ComposerOnly(rows, gd, mark='Y')              # mark envs which exists in composer but not in above lists, and get new rows by joining them.
    celldata = list(gd.values())                                    # get cell data as list[EnvVal]

    extraFields=EnvVal.__statisticsFields__
    if opts.no_statistics == True:
         extraFields=[]

    cols = extraFields + cols                                       # update cols for table schema, according to specified option.
    df = mkTable(rows, cols, celldata,  extraFields=extraFields)    # make table { rows: envs, cols: [extrafields + containers], cell: corresponding value}
    if opts.transpose:
         df = df.T
    writeDF(df, opts.output, writer=opts.writer)                    # save table into file.
