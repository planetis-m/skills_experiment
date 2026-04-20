var p = cast[ptr int](alloc(sizeof(int)))
p[] = 42
dealloc(p)
echo p[]
