(module
  (memory 256 256)
  (type $0 (func))
  (func $a (type $0)
    (call $a)
  )
  (func $b (type $0)
    (call $b)
    (call $b)
  )
  (func $c (type $0)
    (call $c)
    (call $c)
    (call $c)
  )
)