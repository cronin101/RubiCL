#include "ruby.h"

VALUE mMapAddOne(VALUE self, VALUE input) {
    int elements = RARRAY_LEN(input);
    VALUE output = rb_ary_new2(elements);

    for (int i = 0; i < elements; ++i) {
        VALUE transformed = INT2FIX(FIX2INT(rb_ary_entry(input, i)) + 1);
        rb_ary_store(output, i, transformed);
    }

    return output;
}

VALUE mFilterEven(VALUE self, VALUE input) {
    int elements = RARRAY_LEN(input);

    int kept = 0;
    int size = 2;
    VALUE* out = malloc(size * sizeof(VALUE));

    for (int i = 0; i < elements; ++i) {
        VALUE entry = rb_ary_entry(input, i);
        if (FIX2INT(entry) % 2 == 0) {
            if (++kept > size) out = realloc(out, (size *= 2) * sizeof(VALUE));
            out[kept - 1] = entry;
        }
    }

    VALUE output = rb_ary_new2(kept);
    for (int i = 0; i < kept; ++i) rb_ary_store(output, i, out[i]);
    free(out);

    return output;
}

VALUE mFilterModTwen(VALUE self, VALUE input) {
    int elements = RARRAY_LEN(input);

    int kept = 0;
    int size = 2;
    VALUE* out = malloc(size * sizeof(VALUE));

    for (int i = 0; i < elements; ++i) {
        VALUE entry = rb_ary_entry(input, i);
        if (FIX2INT(entry) % 20 == 0) {
            if (++kept > size) out = realloc(out, (size *= 2) * sizeof(VALUE));
            out[kept - 1] = entry;
        }
    }

    VALUE output = rb_ary_new2(kept);
    for (int i = 0; i < kept; ++i) rb_ary_store(output, i, out[i]);
    free(out);

    return output;
}

VALUE mMapAddHalfFilterEven(VALUE self, VALUE input) {
    int elements = RARRAY_LEN(input);

    int kept = 0;
    int size = 2;
    int* out = malloc(size * sizeof(int));

    for (int i = 0; i < elements; ++i) {
        int entry = FIX2INT(rb_ary_entry(input, i));
        entry += entry / 2;
        if (entry % 2 == 0) {
            if (++kept > size) out = realloc(out, (size *= 2) * sizeof(int));
            out[kept - 1] = entry;
        }
    }

    VALUE output = rb_ary_new2(kept);
    for (int i = 0; i < kept; ++i) rb_ary_store(output, i, INT2FIX(out[i]));
    free(out);

    return output;
}
void Init_bespoke_backend() {
    VALUE BespokeBackend = rb_define_module("BespokeBackend");
    rb_define_singleton_method(BespokeBackend, "map_add_one", mMapAddOne, 1);
    rb_define_singleton_method(BespokeBackend, "filter_even", mFilterEven, 1);
    rb_define_singleton_method(BespokeBackend, "filter_modtwen", mFilterModTwen, 1);
    rb_define_singleton_method(BespokeBackend, "map_add_half_filter_even", mMapAddHalfFilterEven, 1);
}
