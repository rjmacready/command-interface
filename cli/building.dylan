module: cli
synopsis: Utilities for constructing CLI node structures.
author: Ingo Albrecht <prom@berlin.ccc.de>
copyright: see accompanying file COPYING

define method root-define-command (root :: <cli-root>, name :: <sequence>,
                                   #rest node-keys,
                                   #key node-class :: <class> = <cli-command>, #all-keys)
 => (cmd :: <cli-symbol>);
  local
    method find-or-make-successor (node :: <cli-node>,
                                   symbol :: <symbol>,
                                   node-class :: <class>,
                                   node-keys :: <sequence>)
      // find symbol in existing successors
      let found = #f;
      for (s in node-successors(node), until: found)
        if (instance?(s, <cli-symbol>) & (node-symbol(s) == symbol))
          found := s;
        end if;
      end for;
      // if not found then make one
      if (~found)
        found := apply(make, node-class, name:, symbol, node-keys);
        node-add-successor(node, found);
      end if;
      // return whatever we have now
      found;
    end;
  // find or create symbol nodes for entire name sequence
  let cur = root;
  for (n in name, i from 0)
    // determine what to instantiate, if needed
    let (cls, keys) =
      if (i == size(name) - 1)
        values(node-class, node-keys);
      else
        values(<cli-symbol>, #[]);
      end;
    // find or make the node
    cur := find-or-make-successor
      (cur, as(<symbol>, n), cls, keys);
  end for;
  // return the last symbol in the chain
  cur;
end method;

define method root-define-command (root :: <cli-root>, name :: <string>,
                                   #rest keys, #key, #all-keys)
 => (cmd :: <cli-symbol>);
  apply(root-define-command, root, list(name), keys);
end method;

define method root-define-command (root :: <cli-root>, name :: <symbol>,
                                   #rest keys, #key, #all-keys)
 => (cmd :: <cli-symbol>);
  apply(root-define-command, root, list(name), keys);
end method;


define function make-param (anchor :: <cli-command>, name :: <symbol>,
                            #rest keys,
                            #key syntax :: <symbol> = #"named",
                                 node-class :: <class> = <cli-string>,
                            #all-keys)
 => (entry :: <cli-node>);
  select (syntax)
      #"named" => apply(make-named-param, anchor, name, keys);
      #"simple" => apply(make-simple-param, anchor, name, keys);
      #"inline" => apply(make-inline-param, anchor, name, keys);
      otherwise => error("Invalid parameter syntax %=", syntax);
  end;
end;

define function make-simple-param (anchor :: <cli-command>, name :: <symbol>,
                                   #rest keys, #key node-class :: <class> = <cli-string>, #all-keys)
 => (entry :: <cli-node>);
  let param = apply(make, node-class,
                    name:, name,
                    anchor:, anchor,
                    priority:, $cli-priority-parameter,
                    keys);
  node-add-successor(anchor, param);
  command-add-parameter(anchor, param);
  param;
end function;

define method make-named-param (anchor :: <cli-command>, names :: <sequence>,
                                #rest keys, #key node-class :: <class> = <cli-string>, #all-keys)
 => (param :: <cli-node>, symbols :: <sequence>);
  let param = apply(make, node-class,
                    name:, element(names, 0),
                    anchor:, anchor,
                    priority:, $cli-priority-parameter,
                    keys);
  let syms = #();
  for (name in names)
    let sym = make(<cli-symbol>,
                   name: as(<symbol>, name),
                   repeatable?: node-repeatable?(param),
                   repeat-marker: param,
                   successors: list(param));
    syms := add(syms, sym);
    node-add-successor(anchor, sym);
  end for;
  command-add-parameter(anchor, param);
  values(param, syms);
end method;

define method make-named-param (anchor :: <cli-command>, name :: <symbol>,
                                #rest keys, #key, #all-keys)
 => (param :: <cli-parameter>, symbols :: <sequence>);
  apply(make-named-param, anchor, list(name), keys);
end method;

define method make-inline-param (anchor :: <cli-command>, names,
                                 #rest keys, #key, #all-keys)
 => (param :: <cli-node>, symbols :: <sequence>);
  let (param, syms) = apply(make-named-param, anchor, names, keys);

  node-add-successor(anchor, param);

  values(param, syms);
end method;
