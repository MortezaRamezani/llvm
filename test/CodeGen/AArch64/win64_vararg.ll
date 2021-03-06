; RUN: llc < %s -mtriple=aarch64-pc-win32 | FileCheck %s

define void @pass_va(i32 %count, ...) nounwind {
entry:
; CHECK: sub     sp, sp, #80
; CHECK: add     x8, sp, #24
; CHECK: add     x0, sp, #24
; CHECK: stp     x6, x7, [sp, #64]
; CHECK: stp     x4, x5, [sp, #48]
; CHECK: stp     x2, x3, [sp, #32]
; CHECK: str     x1, [sp, #24]
; CHECK: stp     x30, x8, [sp]
; CHECK: bl      other_func
; CHECK: ldr     x30, [sp], #80
; CHECK: ret
  %ap = alloca i8*, align 8
  %ap1 = bitcast i8** %ap to i8*
  call void @llvm.va_start(i8* %ap1)
  %ap2 = load i8*, i8** %ap, align 8
  call void @other_func(i8* %ap2)
  ret void
}

declare void @other_func(i8*) local_unnamed_addr

declare void @llvm.va_start(i8*) nounwind
declare void @llvm.va_copy(i8*, i8*) nounwind

; CHECK-LABEL: f9:
; CHECK: sub     sp, sp, #16
; CHECK: add     x8, sp, #24
; CHECK: add     x0, sp, #24
; CHECK: str     x8, [sp, #8]
; CHECK: add     sp, sp, #16
; CHECK: ret
define i8* @f9(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7, i64 %a8, ...) nounwind {
entry:
  %ap = alloca i8*, align 8
  %ap1 = bitcast i8** %ap to i8*
  call void @llvm.va_start(i8* %ap1)
  %ap2 = load i8*, i8** %ap, align 8
  ret i8* %ap2
}

; CHECK-LABEL: f8:
; CHECK: sub     sp, sp, #16
; CHECK: add     x8, sp, #16
; CHECK: add     x0, sp, #16
; CHECK: str     x8, [sp, #8]
; CHECK: add     sp, sp, #16
; CHECK: ret
define i8* @f8(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7, ...) nounwind {
entry:
  %ap = alloca i8*, align 8
  %ap1 = bitcast i8** %ap to i8*
  call void @llvm.va_start(i8* %ap1)
  %ap2 = load i8*, i8** %ap, align 8
  ret i8* %ap2
}

; CHECK-LABEL: f7:
; CHECK: sub     sp, sp, #32
; CHECK: add     x8, sp, #24
; CHECK: str     x7, [sp, #24]
; CHECK: add     x0, sp, #24
; CHECK: str     x8, [sp, #8]
; CHECK: add     sp, sp, #32
; CHECK: ret
define i8* @f7(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, ...) nounwind {
entry:
  %ap = alloca i8*, align 8
  %ap1 = bitcast i8** %ap to i8*
  call void @llvm.va_start(i8* %ap1)
  %ap2 = load i8*, i8** %ap, align 8
  ret i8* %ap2
}

; CHECK-LABEL: copy1:
; CHECK: sub     sp, sp, #80
; CHECK: add     x8, sp, #24
; CHECK: stp     x6, x7, [sp, #64]
; CHECK: stp     x4, x5, [sp, #48]
; CHECK: stp     x2, x3, [sp, #32]
; CHECK: str     x1, [sp, #24]
; CHECK: stp     x8, x8, [sp], #80
; CHECK: ret
define void @copy1(i64 %a0, ...) nounwind {
entry:
  %ap = alloca i8*, align 8
  %cp = alloca i8*, align 8
  %ap1 = bitcast i8** %ap to i8*
  %cp1 = bitcast i8** %cp to i8*
  call void @llvm.va_start(i8* %ap1)
  call void @llvm.va_copy(i8* %cp1, i8* %ap1)
  ret void
}

declare void @llvm.va_end(i8*)
declare void @llvm.lifetime.start.p0i8(i64, i8* nocapture) #1
declare void @llvm.lifetime.end.p0i8(i64, i8* nocapture) #1

declare i32 @__stdio_common_vsprintf(i64, i8*, i64, i8*, i8*, i8*) local_unnamed_addr #3
declare i64* @__local_stdio_printf_options() local_unnamed_addr #4

; CHECK-LABEL: snprintf
; CHECK: sub     sp,  sp, #96
; CHECK: stp     x21, x20, [sp, #16]
; CHECK: stp     x19, x30, [sp, #32]
; CHECK: add     x8, sp, #56
; CHECK: mov     x19, x2
; CHECK: mov     x20, x1
; CHECK: mov     x21, x0
; CHECK: stp     x6, x7, [sp, #80]
; CHECK: stp     x4, x5, [sp, #64]
; CHECK: str     x3, [sp, #56]
; CHECK: str     x8, [sp, #8]
; CHECK: bl      __local_stdio_printf_options
; CHECK: ldr     x8, [x0]
; CHECK: add     x5, sp, #56
; CHECK: mov     x1, x21
; CHECK: mov     x2, x20
; CHECK: orr     x0, x8, #0x2
; CHECK: mov     x3, x19
; CHECK: mov     x4, xzr
; CHECK: bl      __stdio_common_vsprintf
; CHECK: ldp     x19, x30, [sp, #32]
; CHECK: ldp     x21, x20, [sp, #16]
; CHECK: cmp     w0, #0
; CHECK: csinv   w0, w0, wzr, ge
; CHECK: add     sp, sp, #96
; CHECK: ret
define i32 @snprintf(i8*, i64, i8*, ...) local_unnamed_addr #5 {
  %4 = alloca i8*, align 8
  %5 = bitcast i8** %4 to i8*
  call void @llvm.lifetime.start.p0i8(i64 8, i8* nonnull %5) #2
  call void @llvm.va_start(i8* nonnull %5)
  %6 = load i8*, i8** %4, align 8
  %7 = call i64* @__local_stdio_printf_options() #2
  %8 = load i64, i64* %7, align 8
  %9 = or i64 %8, 2
  %10 = call i32 @__stdio_common_vsprintf(i64 %9, i8* %0, i64 %1, i8* %2, i8* null, i8* %6) #2
  %11 = icmp sgt i32 %10, -1
  %12 = select i1 %11, i32 %10, i32 -1
  call void @llvm.va_end(i8* nonnull %5)
  call void @llvm.lifetime.end.p0i8(i64 8, i8* nonnull %5) #2
  ret i32 %12
}

; CHECK-LABEL: fixed_params
; CHECK: sub     sp,  sp, #32
; CHECK: mov     w8,  w3
; CHECK: mov     w9,  w2
; CHECK: mov     w10, w1
; CHECK: str     w4,  [sp]
; CHECK: fmov    x1,  d0
; CHECK: fmov    x3,  d1
; CHECK: fmov    x5,  d2
; CHECK: fmov    x7,  d3
; CHECK: mov     w2,  w10
; CHECK: mov     w4,  w9
; CHECK: mov     w6,  w8
; CHECK: str     x30, [sp, #16]
; CHECK: str     d4,  [sp, #8]
; CHECK: bl      varargs
; CHECK: ldr     x30, [sp, #16]
; CHECK: add     sp,  sp, #32
; CHECK: ret
define void @fixed_params(i32, double, i32, double, i32, double, i32, double, i32, double) nounwind {
  tail call void (i32, ...) @varargs(i32 %0, double %1, i32 %2, double %3, i32 %4, double %5, i32 %6, double %7, i32 %8, double %9)
  ret void
}

declare void @varargs(i32, ...) local_unnamed_addr
