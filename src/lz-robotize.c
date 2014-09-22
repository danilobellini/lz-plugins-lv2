/*
 * Created on Fri 2014-09-19 05:22 BRT
 * License is GPLv3, see COPYING.txt for more details.
 * by Danilo J. S. Bellini
 */
#include "Python.h"
#include "lv2.h"
#include <dlfcn.h>

/****************************************************************************/

#define PLUGIN_URI "http://github.com/danilobellini/lz-plugins-lv2/robotize"
#define SIZE 1024
#define HOP 441

typedef struct{
  float *in, *out;
  PyObject *ns,   /* Python "locals" namespace (dict) */
           *sig,  /* Input changeable deque (signal) object */
           *osig; /* Output Stream iterator (signal) object */
} Plugin;

/****************************************************************************/

static LV2_Handle instantiate(const LV2_Descriptor* descr, double rate,
                              const char* bpath,
                              const LV2_Feature* const* features){
  Plugin *plugin = (Plugin*)malloc(sizeof(Plugin));
  dlopen("libpython2.7.so",       /* RTLD_GLOBAL avoids ImportError due to */
         RTLD_GLOBAL | RTLD_NOW); /* undefined symbols (needed for Numpy)  */
  Py_Initialize();
  plugin->ns = PyDict_New();

  /* Namespace init */
  PyDict_SetItemString(plugin->ns, "__builtins__", PyEval_GetBuiltins());
  PyDict_SetItemString(plugin->ns, "size", PyInt_FromLong(SIZE));
  PyDict_SetItemString(plugin->ns, "hop", PyInt_FromLong(HOP));

  /* Build the AudioLazy effect (Python) */
  PyCompilerFlags flags = {CO_FUTURE_DIVISION};
  if(!PyRun_StringFlags(
    "\nfrom audiolazy import *"
    "\nfrom collections import deque"

    "\nclass IterationChangeableDeque(deque):"
    "\n  __iter__ = lambda self: self"
    "\n  def next(self):"
    "\n    try:"
    "\n      return self.popleft()"
    "\n    except IndexError:"
    "\n      return 0."

    "\nsig = IterationChangeableDeque(maxlen = 2 * size)"
    "\nwnd = window.hann"
    "\nrobotize = stft(abs, size=size, hop=hop, wnd=wnd, ola_wnd=wnd, "
                      "before=None)"
    "\nosig = robotize(sig).__iter__()",

    Py_file_input, plugin->ns, plugin->ns, &flags
  )){
    PyErr_Print();
    return NULL;
  }

  /* Now we've got both the I/O signals and the plugin */
  plugin->sig = PyDict_GetItemString(plugin->ns, "sig");
  plugin->osig = PyDict_GetItemString(plugin->ns, "osig");

  if(!PyErr_Occurred()) return (LV2_Handle)plugin;
  PyErr_Print();
  return NULL;
}

/****************************************************************************/

static void connect_port(LV2_Handle instance, uint32_t port, void *data){
  Plugin *plugin = (Plugin*)instance;
  float **params[] = {&plugin->in, &plugin->out};
  *params[port] = (float*)data;
}

/****************************************************************************/

static void activate(LV2_Handle instance){
};

/****************************************************************************/

static void run(LV2_Handle instance, uint32_t n){
  Plugin *plugin = (Plugin*)instance;
  uint32_t i;
  PyObject *sample = NULL;

  /* Put samples in the input buffer signal ("sig" deque) */
  for (i = 0; i < n; i++)
    PyObject_CallMethod(plugin->sig, "append", "f", plugin->in[i]);

  /* Get samples from the output signal ("osig" Stream iterator) */
  for (i = 0; i < n; i++){
    sample = PyObject_CallMethod(plugin->osig, "next", NULL);
    plugin->out[i] = (float)PyFloat_AS_DOUBLE(sample);
    Py_DECREF(sample);
  }
}

/****************************************************************************/

static void deactivate(LV2_Handle instance){
};

/****************************************************************************/

static void cleanup(LV2_Handle instance){
  Plugin *plugin = (Plugin*)instance;
  Py_XDECREF(plugin->ns);
  Py_Finalize();
  free(plugin);
}

/****************************************************************************/

static const void *extension_data(const char* uri){
  return NULL;
}

/****************************************************************************/

static const LV2_Descriptor PluginDescr = {
  PLUGIN_URI, instantiate, connect_port, activate,
  run, deactivate, cleanup, extension_data
};

LV2_SYMBOL_EXPORT const LV2_Descriptor *lv2_descriptor(uint32_t idx){
  return idx == 0 ? &PluginDescr : NULL;
}
