final: prev: {
  /*
  Merges list of records, concatenates arrays; if two values can't be merged, the latter is preferred.

  Example 1:
    recursiveMerge [
      { a = "x"; c = "m"; list = [1]; }
      { a = "y"; b = "z"; list = [2]; }
    ]

    returns

    { a = "y"; b = "z"; c="m"; list = [1 2] }

  Example 2:
    recursiveMerge [
      {
        a.a = [1];
        a.b = 1;
        a.c = [1 1];
        boot.loader.grub.enable = true;
        boot.loader.grub.device = "/dev/hda";
      }
      {
        a.a = [2];
        a.b = 2;
        a.c = [1 2];
        boot.loader.grub.device = "";
      }
    ]

    returns

    {
      a = {
        a = [ 1 2 ];
        b = 2;
        c = [ 1 2 ];
      };
      boot = {
        loader = {
          grub = {
            device = "";
            enable = true;
          };
        };
      };
    }
  */
  recursiveMerge = attrList: let
    f = attrPath:
      prev.zipAttrsWith (
        name: values:
          if prev.tail values == []
          then prev.head values
          else if prev.all prev.isList values
          then prev.unique (prev.concatLists values)
          else if prev.all prev.isAttrs values
          then f (attrPath ++ [name]) values
          else prev.last values
      );
  in
    f [] attrList;
}
