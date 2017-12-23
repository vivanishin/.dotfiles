set history filename ~/.gdb_history
set history save on
set disassembly-flavor intel
set pagination off
#set history size unlimited
set print elements 0
define ce
  catch syscall exit_group
end

define dump-tree
  call debug_tree ($arg0)
end

document dump-tree
dd <tree>
Used for GCC debugging. Dumps textual representation of the tree provided.
end

alias dd = dump-tree
