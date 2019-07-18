# LOVD caches

Repository storing caches in use by several projects,
 like the [VKGL import script](https://github.com/LOVDnl/VKGL_import).

### NC cache

This file contains variant descriptions on the genome (NC reference sequences) and their normalized counterparts.
The file does not need to be sorted.
An example line looks like:

```
NC_000001.10:g.100387136_100387137insA  NC_000001.10:g.100387137dup
```

Note that both values may be the same, in the case the variant can not be normalized.

The script will store errors using JSON, like so:

```
NC_000001.10:g.150771703C>T     {"EREF":"C not found at position 150771703, found T instead."}
```

### Mapping cache

The mapping cache contains mapping data from two Mutalyzer webservices, both the `runMutalyzerLight` and
 the `numberConversion` methods.
Because both methods provide partially overlapping data, the results are stored together.
The cache stores the method(s) used, so that your scripts can decide
 on whether using an additional method could be useful.

The file does not need to be sorted, but sorting may help in finding duplicate variants.
An example line looks like:

```
NC_000001.10:g.100154502A>G     {"NM_017734.4":{"c":"c.686A>G","p":"p.(Asn229Ser)"},"methods":["runMutalyzerLight"]}
NC_000001.10:g.13413980G>A      {"NM_001291381.1":{"c":"c.923G>A","p":"p.?"},"methods":["runMutalyzerLight","numberConversion"]}
NC_000001.10:g.13634793G>T      {"methods":["runMutalyzerLight","numberConversion"]}
```

The third line in this example shows a variant where no mapping data could be found, using either Mutalyzer method.
