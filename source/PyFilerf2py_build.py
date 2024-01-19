import numpy.f2py
import sys
import os
from numpy.f2py.auxfuncs import gentitle
import time
import subprocess
sys.path.append(r"C:/Program Files (x86)/Intel/oneAPI/compiler/2023.2.1/windows/redist/intel64_win/compiler")
os.add_dll_directory(r"C:/Program Files (x86)/Intel/oneAPI/compiler/2023.2.1/windows/redist/intel64_win/compiler")
generationtime = int(os.environ.get('SOURCE_DATE_EPOCH', time.time()))
numpy.f2py.rules.module_rules = {
    'modulebody': """\
/* File: #modulename#module.c
 * This file is auto-generated with f2py (version:#f2py_version#).
 * f2py is a Fortran to Python Interface Generator (FPIG), Second Edition,
 * written by Pearu Peterson <pearu@cens.ioc.ee>.
 * Generation date: """ + time.asctime(time.gmtime(generationtime)) + """
 * Do not edit this file directly unless you know what you are doing!!!
 */

#ifdef __cplusplus
extern \"C\" {
#endif

""" + gentitle("See f2py2e/cfuncs.py: includes") + """
#includes#
#includes0#

""" + gentitle("See f2py2e/rules.py: mod_rules['modulebody']") + """
static PyObject *#modulename#_error;
static PyObject *#modulename#_module;

""" + gentitle("See f2py2e/cfuncs.py: typedefs") + """
#typedefs#

""" + gentitle("See f2py2e/cfuncs.py: typedefs_generated") + """
#typedefs_generated#

""" + gentitle("See f2py2e/cfuncs.py: cppmacros") + """
#cppmacros#

""" + gentitle("See f2py2e/cfuncs.py: cfuncs") + """
#cfuncs#

""" + gentitle("See f2py2e/cfuncs.py: userincludes") + """
#userincludes#

""" + gentitle("See f2py2e/capi_rules.py: usercode") + """
#usercode#

/* See f2py2e/rules.py */
#externroutines#

""" + gentitle("See f2py2e/capi_rules.py: usercode1") + """
#usercode1#

""" + gentitle("See f2py2e/cb_rules.py: buildcallback") + """
#callbacks#

""" + gentitle("See f2py2e/rules.py: buildapi") + """
#body#

""" + gentitle("See f2py2e/f90mod_rules.py: buildhooks") + """
#f90modhooks#

""" + gentitle("See f2py2e/rules.py: module_rules['modulebody']") + """

""" + gentitle("See f2py2e/common_rules.py: buildhooks") + """
#commonhooks#

""" + gentitle("See f2py2e/rules.py") + """

static FortranDataDef f2py_routine_defs[] = {
#routine_defs#
\t{NULL}
};

static PyMethodDef f2py_module_methods[] = {
#pymethoddef#
\t{NULL,NULL}
};

static struct PyModuleDef moduledef = {
\tPyModuleDef_HEAD_INIT,
\t"#modulename#",
\tNULL,
\t-1,
\tf2py_module_methods,
\tNULL,
\tNULL,
\tNULL,
\tNULL
};

PyMODINIT_FUNC PyInit_#modulename#(void) {
\tint i;
\tPyObject *m,*d, *s, *tmp;
\tm = #modulename#_module = PyModule_Create(&moduledef);
\tPy_SET_TYPE(&PyFortran_Type, &PyType_Type);
\timport_array();
\tif (PyErr_Occurred())
\t\t{PyErr_SetString(PyExc_ImportError, \"can't initialize module #modulename# (failed to import numpy)\"); return m;}
\td = PyModule_GetDict(m);
\ts = PyString_FromString(\"$R""" + """evision: $\");
\tPyDict_SetItemString(d, \"__version__\", s);
\tPy_DECREF(s);
\ts = PyUnicode_FromString(
\t\t\"This module '#modulename#' is auto-generated with f2py (version:#f2py_version#).\\nFunctions:\\n\"\n\".\");
\tPyDict_SetItemString(d, \"__doc__\", s);
\tPy_DECREF(s);
\t#modulename#_error = PyErr_NewException (\"#modulename#.error\", NULL, NULL);
\t/*
\t * Store the error object inside the dict, so that it could get deallocated.
\t * (in practice, this is a module, so it likely will not and cannot.)
\t */
\tPyDict_SetItemString(d, \"_#modulename#_error\", #modulename#_error);
\tPy_DECREF(#modulename#_error);
\tfor(i=0;f2py_routine_defs[i].name!=NULL;i++) {
\t\ttmp = PyFortranObject_NewAsAttr(&f2py_routine_defs[i]);
\t\tPyDict_SetItemString(d, f2py_routine_defs[i].name, tmp);
\t\tPy_DECREF(tmp);
\t}
#initf2pywraphooks#
#initf90modhooks#
#initcommonhooks#
#interface_usercode#

#ifdef F2PY_REPORT_ATEXIT
\tif (! PyErr_Occurred())
\t\ton_exit(f2py_report_on_exit,(void*)\"#modulename#\");
#endif
\treturn m;
}
#ifdef __cplusplus
}
#endif
""",
    'separatorsfor': {'latexdoc': '\n\n',
                      'restdoc': '\n\n'},
    'latexdoc': ['\\section{Module \\texttt{#texmodulename#}}\n',
                 '#modnote#\n',
                 '#latexdoc#'],
    'restdoc': ['Module #modulename#\n' + '=' * 80,
                '\n#restdoc#']
}

# Compiling .o files
ifort = r'C:/Progra~2/Intel/oneAPI/compiler/2023.2.1/windows/bin/intel64/ifort.exe'
# cl = r'C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\bin\amd64\cl.exe'
comp_flags = []
comp_flags += ['/free']
comp_flags += ['/traceback']
comp_flags += ['/Qzero']
comp_flags += ['/Qsave']
comp_flags += ['/names:lowercase']
comp_flags += ['/assume:underscore']
comp_flags += ['/c']
comp_flags += ['/include:../includes']
comp_flags += ['/assume:byterecl']
comp_flags += ['/assume:source_include']
comp_flags += ['/nolist']
comp_flags += ['/static']
comp_flags += ['/heap-arrays0']

subprocess.run([ifort, 'filer.f'   , '/object:filer.o'   ] + comp_flags)
subprocess.run([ifort, 'fwk1io.f'  , '/object:fwk1io.o'  ] + comp_flags)
subprocess.run([ifort, 'cio4wk1.f' , '/object:cio4wk1.o' ] + comp_flags)
subprocess.run([ifort, 'gdxf9def.f', '/object:gdxf9def.o'] + comp_flags)
subprocess.run([ifort, 'filemgr.f' , '/object:filemgr.o' ] + comp_flags)

# TODO: figure out how to compile gdxf9glu.c from python/command line. Currently, gdxf9clu.c needs to be compiled
#  outside of this Python Script using the arugments below in (VS2015 x64 Native Tools Command Prompt.
#  User needs to confirm pathing to their respective path.
# L:\main\jmw\git\nems_test\source>cl -DAPIWRAP_LCASE_NODECOR -c gdxf9glu.c -I../includes /Fogdxf9glu.o

#Potential path forward to call? Unsure how to map to call correctly.
# subprocess.run([cl, '-DAPIWRAP_LCASE_NODECOR', '-c', 'gdxf9glu.c', '-I../includes', '/Fogdxf9glu.o'], env=cl_env) # , '/free', '/names:lowercase', '/assume:underscore', '/c', '/include:../includes', '/object:gdxf9def.o'])

# Create signature file for pyfiler.f, don't know if this is strictly necessary if we're intending to access every function
#  in pyfiler.f
numpy.f2py.run_main(['-h',
                     'pyfiler.pyf',
                     'PyFiler.f90',
                     '-m', 'pyfiler',
                     # 'only:', 'init_filer', 'get_data',
                     '--include-paths', r'../includes',
                     '--overwrite-signature'])

# Load arguments for compilation
# first flags for ifort, note these we mostly taken from the makefile in nems/source, these might not all be necessary
# TODO: work on fixing this path issue for other users. Make it so that it points to correct path for all.
flags   = r'/free /Qzero /debug:full /assume:nounderscore /IL:/main/jmw/git/NEMS23/includes '
flags   += r'/compile_only /nopdbfile /traceback /fpconstant /assume:byterecl /assume:source_include /nolist /static /Qsave /heap-arrays0'

# arguments to be passed to f2py for compilation/linking
sys.argv.extend(['-c',
                 'PyFiler.f90',
                 'pyfiler.pyf',
                 'filer.o',
                 'fwk1io.o',
                 'cio4wk1.o',
                 'gdxf9def.o',
                 'gdxf9glu.o',
                 'filemgr.o',
                 '--include-paths', r'../includes',
                 '-m', 'pyfiler',
                 r'-LC:\Progra~2\Intel\oneAPI\compiler\2023.2.1\windows\compiler\lib\intel64_win',
                 '--fcompiler=intelvem',
                 '--f90flags='+flags])

# debug to have f2py list the Fortran compilers it can find
# sys.argv.extend(['-c', '--help-fcompiler'])

# Load the path needed fro f2py to find ifort
os.environ['PATH'] += r';C:/Progra~2/Intel/oneAPI/compiler/2023.2.1/windows/bin/intel64'
#C:\Program Files (x86)\Intel\oneAPI\compiler\2023.2.1\windows\bin\intel64
numpy.f2py.main()
# import run_f2py
pass
