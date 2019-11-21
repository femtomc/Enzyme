; RUN: %opt < %s %loadEnzyme -enzyme -enzyme_preopt=false -mem2reg -sroa -instsimplify -simplifycfg -S | FileCheck %s

@.str = private unnamed_addr constant [4 x i8] c"%f\0A\00", align 1
@.str.1 = private unnamed_addr constant [5 x i8] c"%f \0A\00", align 1

; Function Attrs: noinline nounwind uwtable
declare dso_local double @read() local_unnamed_addr #0

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.start.p0i8(i64, i8* nocapture) #1

; Function Attrs: nounwind
declare dso_local i32 @scanf(i8* nocapture readonly, ...) local_unnamed_addr #2

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.end.p0i8(i64, i8* nocapture) #1

; Function Attrs: noinline nounwind uwtable
define dso_local double @sub(double %x) local_unnamed_addr #0 {
entry:
  %call = tail call fast double @read() #3
  %mul = fmul fast double %call, %x
  %call1 = tail call fast float @flread() #3
  %conv = fpext float %call1 to double
  %mul2 = fmul fast double %mul, %conv
  ret double %mul2
}

; Function Attrs: noinline nounwind uwtable
declare dso_local double @read2() local_unnamed_addr #0

declare dso_local float @flread() local_unnamed_addr #1

; Function Attrs: noinline nounwind uwtable
define dso_local double @foo(double %x) #0 {
entry:
  %call = tail call fast double @sub(double %x)
  %call1 = tail call fast double @read2()
  %add = fadd fast double %call1, %call
  ret double %add
}

; Function Attrs: nounwind uwtable
define dso_local double @dsumsquare(double %x) local_unnamed_addr #3 {
entry:
  %0 = tail call double (double (double)*, ...) @__enzyme_autodiff(double (double)* nonnull @foo, double %x)
  ret double %0
}

; Function Attrs: nounwind
declare double @__enzyme_autodiff(double (double)*, ...) #4

attributes #0 = { noinline nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-jump-tables"="false" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #1 = { argmemonly nounwind }
attributes #2 = { nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #3 = { nounwind uwtable "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="false" "no-infs-fp-math"="true" "no-jump-tables"="false" "no-nans-fp-math"="true" "no-signed-zeros-fp-math"="true" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="true" "use-soft-float"="false" }
attributes #4 = { nounwind }

!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 7.1.0 "}
!2 = !{!3, !3, i64 0}
!3 = !{!"double", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}

; CHECK: define internal {{(dso_local )?}}{ double } @diffefoo(double %x, double %differeturn)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %[[augsub:.+]] = call { { float, double }, double } @augmented_sub(double %x)
; CHECK-NEXT:   %[[tape:.+]] = extractvalue { { float, double }, double } %[[augsub]], 0
; CHECK-NEXT:   %call1 = tail call fast double @read2()
; CHECK-NEXT:   %[[result:.+]] = call { double } @diffesub(double %x, double %differeturn, { float, double } %[[tape]])
; CHECK-NEXT:   ret { double } %[[result]]
; CHECK-NEXT: }

; CHECK: define internal {{(dso_local )?}}{ { float, double }, double } @augmented_sub(double %x)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %call = tail call fast double @read()
; CHECK-NEXT:   %mul = fmul fast double %call, %x
; CHECK-NEXT:   %call1 = tail call fast float @flread()
; CHECK-NEXT:   %conv = fpext float %call1 to double
; CHECK-NEXT:   %mul2 = fmul fast double %mul, %conv
; CHECK-NEXT:   %[[insertcache1:.+]] = insertvalue { { float, double }, double } undef, float %call1, 0, 0
; CHECK-NEXT:   %[[insertcache2:.+]] = insertvalue { { float, double }, double } %[[insertcache1]], double %call, 0, 1
; CHECK-NEXT:   %[[insertreturn:.+]] = insertvalue { { float, double }, double } %[[insertcache2]], double %mul2, 1
; CHECK-NEXT:   ret { { float, double }, double } %[[insertreturn]]
; CHECK-NEXT: }

; CHECK: define internal {{(dso_local )?}}{ double } @diffesub(double %x, double %differeturn, { float, double } %tapeArg)
; CHECK-NEXT: entry:
; CHECK-NEXT:   %[[flreadextract:.+]] = extractvalue { float, double } %tapeArg, 0
; CHECK-NEXT:   %[[fpext:.+]] = fpext float %[[flreadextract]] to double
; CHECK-NEXT:   %[[fmul:.+]] = fmul fast double %differeturn, %[[fpext]]
; CHECK-NEXT:   %[[readextract:.+]] = extractvalue { float, double } %tapeArg, 1
; CHECK-NEXT:   %[[fmul2:.+]] = fmul fast double %[[fmul]], %[[readextract]]
; CHECK-NEXT:   %[[ret:.+]] = insertvalue { double } undef, double %[[fmul2]], 0
; CHECK-NEXT:   ret { double } %[[ret]]
; CHECK-NEXT: }
