import Mathlib.MeasureTheory.Integral.MeanInequalities
import Mathlib.MeasureTheory.Function.L1Space
import Mathlib.MeasureTheory.Function.LpSpace
import Mathlib.Analysis.SpecialFunctions.Pow.Continuity
import Mathlib.Analysis.NormedSpace.Dual
import Mathlib.Analysis.NormedSpace.LinearIsometry
import Mathlib.MeasureTheory.Integral.Bochner
import Mathlib.Data.Real.Sign
import Mathlib.Tactic.FunProp.Measurable

/-! We show that the dual space of `L^p` for `1 ≤ p < ∞`.

See [Stein-Shakarchi, Functional Analysis, section 1.4] -/
noncomputable section

open Real NNReal ENNReal NormedSpace MeasureTheory
section

variable {α 𝕜 E E₁ E₂ E₃ : Type*} {m : MeasurableSpace α} {p p' q q' : ℝ≥0∞}
  {μ : Measure α} [NontriviallyNormedField 𝕜]
  [NormedAddCommGroup E] [NormedSpace 𝕜 E] [FiniteDimensional 𝕜 E]
  [NormedAddCommGroup E₁] [NormedSpace 𝕜 E₁] [FiniteDimensional 𝕜 E₁]
  [NormedAddCommGroup E₂] [NormedSpace 𝕜 E₂] [FiniteDimensional 𝕜 E₂]
  [NormedAddCommGroup E₃] [NormedSpace 𝕜 E₃] [FiniteDimensional 𝕜 E₃]
  [MeasurableSpace E] [BorelSpace E]
  [MeasurableSpace E₁] [BorelSpace E₁]
  [MeasurableSpace E₂] [BorelSpace E₂]
  [MeasurableSpace E₃] [BorelSpace E₃]
  (L : E₁ →L[𝕜] E₂ →L[𝕜] E₃)

namespace ENNReal

/-- Two numbers `p, q : ℝ≥0∞` are conjugate if `p⁻¹ + q⁻¹ = 1`.
This does allow for the case where one of them is `∞` and the other one is `1`,
in contrast to `NNReal.IsConjExponent`. -/
@[mk_iff]
structure IsConjExponent (p q : ℝ≥0∞) : Prop where
  inv_add_inv_conj : p⁻¹ + q⁻¹ = 1

namespace IsConjExponent

lemma symm (hpq : p.IsConjExponent q) : q.IsConjExponent p := by
    rw [isConjExponent_iff, add_comm, hpq.inv_add_inv_conj]

lemma one_le_left (hpq : p.IsConjExponent q) : 1 ≤ p := by
  simp_rw [← ENNReal.inv_le_one, ← hpq.inv_add_inv_conj, self_le_add_right]

lemma one_le_right (hpq : p.IsConjExponent q) : 1 ≤ q := hpq.symm.one_le_left

lemma left_ne_zero (hpq : p.IsConjExponent q) : p ≠ 0 :=
  zero_lt_one.trans_le hpq.one_le_left |>.ne'

lemma right_ne_zero (hpq : p.IsConjExponent q) : q ≠ 0 :=
  hpq.symm.left_ne_zero

lemma left_inv_ne_top (hpq : p.IsConjExponent q) : p⁻¹ ≠ ∞ := by
  simp_rw [inv_ne_top]
  exact hpq.left_ne_zero

lemma right_inv_ne_top (hpq : p.IsConjExponent q) : q⁻¹ ≠ ∞ := hpq.symm.left_inv_ne_top

lemma left_eq (hpq : p.IsConjExponent q) : p = (1 - q⁻¹)⁻¹ := by
  simp_rw [← inv_eq_iff_eq_inv]
  exact (ENNReal.cancel_of_ne hpq.right_inv_ne_top).eq_tsub_of_add_eq hpq.inv_add_inv_conj

lemma right_eq (hpq : p.IsConjExponent q) : q = (1 - p⁻¹)⁻¹ := hpq.symm.left_eq

lemma inj_right (hpq : p.IsConjExponent q) (hpq' : p.IsConjExponent q') : q = q' := by
  rw [hpq.right_eq, hpq'.right_eq]

lemma inj_left (hpq : p.IsConjExponent q) (hpq' : p'.IsConjExponent q) : p = p' :=
  hpq.symm.inj_right hpq'.symm

lemma left_eq_left_iff_right_eq_right (hpq : p.IsConjExponent q) (hpq' : p'.IsConjExponent q') :
    p = p' ↔ q = q' := by
  constructor <;> rintro rfl <;> [apply inj_right; apply inj_left] <;> assumption

lemma one_top : (1 : ℝ≥0∞).IsConjExponent ∞ := ⟨by simp⟩

lemma top_one : (∞ : ℝ≥0∞).IsConjExponent 1 := ⟨by simp⟩

lemma left_eq_one_iff (hpq : p.IsConjExponent q) : p = 1 ↔ q = ∞ :=
  hpq.left_eq_left_iff_right_eq_right .one_top

lemma left_eq_top_iff (hpq : p.IsConjExponent q) : p = ∞ ↔ q = 1 :=
  (left_eq_one_iff hpq.symm).symm

lemma one_lt_left_iff (hpq : p.IsConjExponent q) : 1 < p ↔ q ≠ ∞ := by
  rw [← not_iff_not, not_lt, ne_eq, not_not, hpq.one_le_left.le_iff_eq, hpq.left_eq_one_iff]

lemma left_ne_top_iff (hpq : p.IsConjExponent q) : p ≠ ∞ ↔ 1 < q :=
  (one_lt_left_iff hpq.symm).symm

lemma _root_.NNReal.IsConjExponent.coe_ennreal {p q : ℝ≥0} (hpq : p.IsConjExponent q) :
    (p : ℝ≥0∞).IsConjExponent q where
  inv_add_inv_conj := by
    have := hpq.symm.ne_zero
    have := hpq.ne_zero
    rw_mod_cast [hpq.inv_add_inv_conj]

lemma toNNReal {p q : ℝ≥0∞} (hp : p ≠ ∞) (hq : q ≠ ∞) (hpq : p.IsConjExponent q) :
    p.toNNReal.IsConjExponent q.toNNReal where
  one_lt := by
    rwa [← coe_lt_coe, coe_toNNReal hp, coe_one, hpq.one_lt_left_iff]
  inv_add_inv_conj := by
    rw [← coe_inj, coe_add, coe_inv, coe_inv, coe_one, coe_toNNReal hp, coe_toNNReal hq,
      hpq.inv_add_inv_conj]
    · exact (toNNReal_ne_zero).mpr ⟨hpq.right_ne_zero, hq⟩
    · exact (toNNReal_ne_zero).mpr ⟨hpq.left_ne_zero, hp⟩

lemma mul_eq_add (hpq : p.IsConjExponent q) : p * q = p + q := by
  induction p using recTopCoe
  . simp [hpq.right_ne_zero]
  induction q using recTopCoe
  . simp [hpq.left_ne_zero]
  norm_cast
  exact hpq.toNNReal coe_ne_top coe_ne_top |>.mul_eq_add

lemma induction
    (P : (p q : ℝ≥0∞) → (p.IsConjExponent q) → Prop)
    (nnreal : ∀ ⦃p q : ℝ≥0⦄, (h : p.IsConjExponent q) → P p q h.coe_ennreal)
    (one : P 1 ∞ one_top) (infty : P ∞ 1 top_one) {p q : ℝ≥0∞} (h : p.IsConjExponent q) :
    P p q h := by
  induction p using recTopCoe
  . simp_rw [h.left_eq_top_iff.mp rfl, infty]
  induction q using recTopCoe
  . simp_rw [h.left_eq_one_iff.mpr rfl, one]
  exact nnreal <| h.toNNReal coe_ne_top coe_ne_top

lemma induction_symm
    (P : (p q : ℝ≥0∞) → (p.IsConjExponent q) → Prop)
    (nnreal : ∀ ⦃p q : ℝ≥0⦄, (h : p.IsConjExponent q) → p ≤ q → P p q h.coe_ennreal)
    (one : P 1 ∞ one_top)
    (symm : ∀ ⦃p q : ℝ≥0∞⦄, (h : p.IsConjExponent q) → P p q h → P q p h.symm)
    {p q : ℝ≥0∞} (h : p.IsConjExponent q) : P p q h := by
  induction h using IsConjExponent.induction
  case nnreal p q h =>
    rcases le_total p q with hpq|hqp
    · exact nnreal h hpq
    · exact symm h.coe_ennreal.symm (nnreal h.symm hqp)
  case one => exact one
  case infty => exact symm .one_top one

/- Versions of Hölder's inequality.
Note that the hard case already exists as `ENNReal.lintegral_mul_le_Lp_mul_Lq`. -/

lemma _root_.ContinuousLinearMap.le_opNNNorm₂ (L : E₁ →L[𝕜] E₂ →L[𝕜] E₃) (x : E₁) (y : E₂) :
    ‖L x y‖₊ ≤ ‖L‖₊ * ‖x‖₊ * ‖y‖₊ := L.le_opNorm₂ x y

lemma lintegral_mul_le_one_top (μ : Measure α) {f : α → E₁} {g : α → E₂}
    (hf : AEMeasurable f μ) : ∫⁻ a, ‖f a‖₊ * ‖g a‖₊ ∂μ ≤ snorm f 1 μ * snorm g ⊤ μ := by
    calc ∫⁻ a, ‖f a‖₊ * ‖g a‖₊ ∂μ ≤ ∫⁻ (a : α), ‖f a‖₊ * snormEssSup g μ ∂μ := MeasureTheory.lintegral_mono_ae (h := by
        rw [Filter.eventually_iff, ← Filter.exists_mem_subset_iff]
        use {a | ↑‖g a‖₊ ≤ snormEssSup g μ}
        rw [← Filter.eventually_iff]
        exact ⟨ae_le_snormEssSup, by simp; intro _ ha; apply ENNReal.mul_left_mono ha⟩)
    _ = snorm f 1 μ * snorm g ⊤ μ := by
      rw [lintegral_mul_const'' _ hf.ennnorm]
      simp [snorm, snorm']

theorem lintegral_mul_le (hpq : p.IsConjExponent q) (μ : Measure α) {f : α → E₁} {g : α → E₂}
    (hf : AEMeasurable f μ) (hg : AEMeasurable g μ) :
    ∫⁻ a, ‖L (f a) (g a)‖₊ ∂μ ≤ ‖L‖₊ * snorm f p μ * snorm g q μ := by
  calc ∫⁻ a, ‖L (f a) (g a)‖₊ ∂μ ≤ ∫⁻ a, ‖L‖₊ * (‖f a‖₊ * ‖g a‖₊) ∂μ := by
        simp_rw [← mul_assoc]; exact lintegral_mono_nnreal fun a ↦ L.le_opNNNorm₂ (f a) (g a)
    _ = ‖L‖₊ * ∫⁻ a, ‖f a‖₊ * ‖g a‖₊ ∂μ := lintegral_const_mul' _ _ coe_ne_top
    _ ≤ ‖L‖₊ * (snorm f p μ * snorm g q μ) := ?_
    _ = ‖L‖₊ * snorm f p μ * snorm g q μ := by rw [mul_assoc]
  gcongr
  induction hpq using IsConjExponent.induction
  case nnreal p q hpq =>
    calc
      ∫⁻ a, ‖f a‖₊ * ‖g a‖₊ ∂μ = ∫⁻ a, ((‖f ·‖₊) * (‖g ·‖₊)) a ∂μ := by
        apply lintegral_congr
        simp only [Pi.mul_apply, coe_mul, implies_true]
      _ ≤ snorm f p μ * snorm g q μ := by
        simp only [coe_mul, snorm, coe_eq_zero, coe_ne_top, ↓reduceIte, coe_toReal, mul_ite, mul_zero, ite_mul, zero_mul, hpq.ne_zero, hpq.symm.ne_zero, snorm']
        apply ENNReal.lintegral_mul_le_Lp_mul_Lq _ (NNReal.isConjExponent_coe.mpr hpq)
        . apply hf.ennnorm
        . apply hg.ennnorm
  case one => exact lintegral_mul_le_one_top _ hf
  case infty =>
    calc
      ∫⁻ a, ‖f a‖₊ * ‖g a‖₊ ∂μ = ∫⁻ a, ‖g a‖₊ * ‖f a‖₊ ∂μ := by simp_rw [mul_comm]
    _ ≤ snorm f ⊤ μ * snorm g 1 μ := by rw [mul_comm]; exact lintegral_mul_le_one_top _ hg

theorem integrable_bilin (hpq : p.IsConjExponent q) (μ : Measure α) {f : α → E₁} {g : α → E₂}
    (hf : Memℒp f p μ) (hg : Memℒp g q μ) :
    Integrable (fun a ↦ L (f a) (g a)) μ := by
  use L.aestronglyMeasurable_comp₂ hf.aestronglyMeasurable hg.aestronglyMeasurable
  apply lintegral_mul_le L hpq μ hf.aestronglyMeasurable.aemeasurable
    hg.aestronglyMeasurable.aemeasurable |>.trans_lt
  exact ENNReal.mul_lt_top (ENNReal.mul_ne_top coe_ne_top hf.snorm_ne_top) hg.snorm_ne_top

end IsConjExponent

end ENNReal

end

section
namespace MeasureTheory
namespace Lp
open ENNReal.IsConjExponent

variable {α E E₁ E₂ E₃ : Type*} {m : MeasurableSpace α} {p q : ℝ≥0∞}
  {μ : Measure α}
  [NormedAddCommGroup E] [NormedSpace ℝ E] [FiniteDimensional ℝ E]
  [NormedAddCommGroup E₁] [NormedSpace ℝ E₁] [FiniteDimensional ℝ E₁]
  [NormedAddCommGroup E₂] [NormedSpace ℝ E₂] [FiniteDimensional ℝ E₂]
  [NormedAddCommGroup E₃] [NormedSpace ℝ  E₃] [FiniteDimensional ℝ  E₃]
  [MeasurableSpace E] [BorelSpace E]
  [MeasurableSpace E₁] [BorelSpace E₁]
  [MeasurableSpace E₂] [BorelSpace E₂]
  [MeasurableSpace E₃] [BorelSpace E₃]
  (L : E₁ →L[ℝ] E₂ →L[ℝ] E₃)

variable
  [hpq : Fact (p.IsConjExponent q)] [h'p : Fact (p < ∞)]
  [hp : Fact (1 ≤ p)] [hq : Fact (1 ≤ q)] -- note: these are superfluous, but it's tricky to make them instances.

lemma hp₀ : p ≠ 0 := left_ne_zero hpq.out
lemma hpᵢ : p ≠ ∞ := lt_top_iff_ne_top.mp h'p.out
lemma hp₀' : p.toReal ≠ 0 := by
  apply toReal_ne_zero.mpr
  exact ⟨hp₀ (q := q), hpᵢ⟩
lemma hp_gt_zero : p > 0 := by
  calc p ≥ 1 := by exact hp.out
       _ > 0 := by simp
lemma hp_gt_zero' : p.toReal > 0 := by
  apply (toReal_pos_iff_ne_top p).mpr
  exact hpᵢ
lemma hp_ge_zero : p ≥ 0 := by simp
lemma hp_ge_zero' : p.toReal ≥ 0 := by apply toReal_nonneg

lemma hq₀ : q ≠ 0 := right_ne_zero hpq.out
lemma hq₀' (hqᵢ : q ≠ ∞) : q.toReal ≠ 0 := by
  apply toReal_ne_zero.mpr
  exact ⟨hq₀ (p := p), hqᵢ⟩
lemma hq_gt_zero : q > 0 := by
  calc q ≥ 1 := by exact hq.out
       _ > 0 := by simp
lemma hq_gt_zero' (hqᵢ : q ≠ ∞) : q.toReal > 0 := by
  apply (toReal_pos_iff_ne_top q).mpr
  exact hqᵢ
lemma hq_ge_zero : q ≥ 0 := by simp
lemma hq_ge_zero' : q.toReal ≥ 0 := by aesop

lemma add_conj_exponent : p + q = p * q := hpq.out.mul_eq_add.symm

lemma add_conj_exponent' (hqᵢ : q ≠ ∞) : p.toReal + q.toReal = p.toReal*q.toReal := by
  rw[←toReal_add hpᵢ hqᵢ]
  rw[←toReal_mul]
  congr
  exact add_conj_exponent

lemma div_self_p : p / p = 1 := by
  rw[ENNReal.div_self (a := p)]
  exact left_ne_zero hpq.out
  exact hpᵢ

lemma div_conj_exponent_ne_top (hqᵢ : q ≠ ∞) : q / p ≠ ∞ := by
  by_contra!
  have := (@ENNReal.div_eq_top q p).mp this
  contrapose! this
  constructor
  . intro _; exact (hp₀ (q := q))
  . intro _; contradiction

lemma div_conj_exponent : q / p + 1 = q := by
  calc _ = q / p + p / p := by rw[ENNReal.div_self (hp₀ (q := q)) hpᵢ];
       _ = (q + p) / p := by rw[←ENNReal.add_div]
       _ = (p + q) / p := by rw[add_comm]
       _ = (p * q) / p := by rw[add_conj_exponent]
       _ = (p * q) / (p * 1) := by rw[mul_one]
       _ = q / 1 := by rw[ENNReal.mul_div_mul_left _ _ (hp₀ (q := q)) hpᵢ]
       _ = q := by rw[div_one]

lemma div_conj_exponent' (hqᵢ : q ≠ ∞) : q.toReal / p.toReal + 1 = q.toReal := by
  calc _ = (q / p).toReal + 1 := by rw[toReal_div]
       _ = (q / p + 1).toReal := by rw[toReal_add]; simp; exact div_conj_exponent_ne_top hqᵢ; simp
       _ = q.toReal := by rw[div_conj_exponent]

lemma div_conj_exponent'' (hqᵢ : q ≠ ∞) : q.toReal / p.toReal = q.toReal - 1 := by
  calc _ = q.toReal / p.toReal + 1 - 1 := by simp
       _ = q.toReal - 1 := by rw[div_conj_exponent' hqᵢ]

lemma toNNReal_eq_toNNreal_of_toReal (x : ℝ≥0∞) :
    x.toReal.toNNReal = x.toNNReal := by aesop

lemma ENNReal.rpow_of_NNReal_ne_top (x : ℝ≥0) (y : ℝ) (hynneg : y ≥ 0)
    : (x : ℝ≥0∞) ^ y ≠ ∞ := by aesop

open ContinuousLinearMap
open Memℒp

section BasicFunctions

def step' : ℝ → ℝ := Set.piecewise {x | x ≤ 0} 0 1

@[fun_prop, measurability]
theorem measurable_step' : Measurable step' := by
  apply Measurable.piecewise
  . apply measurableSet_le
    . apply measurable_id
    . apply measurable_const
  . apply measurable_const
  . apply measurable_const

lemma sign_eq_step : Real.sign = fun x => step' x - step' (-x) := by
  ext x
  simp only [Real.sign, step']
  by_cases h₁ : x < 0
  . have h₂ : x ≤ 0 := by linarith
    have h₃ : ¬ 0 ≤ x := by linarith
    simp [h₁, h₂, h₃]
  . by_cases h₂ : 0 < x
    . have h₃ : 0 ≤ x := by linarith
      have h₄ : ¬ x ≤ 0 := by linarith
      simp[h₁, h₂, h₃, h₄]
    . have h₃ : x = 0 := by linarith
      simp[h₁, h₂, h₃]

@[fun_prop, measurability]
theorem measurable_sign : Measurable (Real.sign : ℝ → ℝ) := by
  rw[sign_eq_step]
  fun_prop

@[simp]
theorem abs_of_sign (x) : |Real.sign x| = if x = 0 then 0 else 1 := by
  dsimp[_root_.abs, Real.sign]
  by_cases h₁ : x < 0
  . have h₂ : x ≠ 0 := by linarith
    simp[h₁, h₂]
  . by_cases h₂ : x = 0
    . simp[h₁, h₂]
    . have h₃ : 0 < x := by
        apply lt_of_le_of_ne
        simp at h₁
        exact h₁
        symm
        exact h₂
      simp[h₁, h₂, h₃]

@[simp]
theorem nnnorm_of_sign (x) : ‖Real.sign x‖₊ = if x = 0 then 0 else 1 := by aesop
  -- ext
  -- rw [coe_nnnorm, norm_eq_abs, abs_of_sign, apply_ite toReal]
  -- rfl

theorem rpow_of_nnnorm_of_sign (x y : ℝ) (hypos : y > 0)
    : (‖Real.sign x‖₊ : ℝ≥0∞) ^ y = if x = 0 then 0 else 1 := by aesop


def NNReal.rpow' (y : ℝ) (x : ℝ≥0) : ℝ≥0 := NNReal.rpow x y

def ENNReal.rpow' (y : ℝ) (x : ℝ≥0∞) : ℝ≥0∞ := ENNReal.rpow x y

theorem NNReal.rpow'_eq_rpow (x : ℝ≥0) (y : ℝ) : NNReal.rpow' y x = x^y := rfl

theorem ENNReal.rpow'_eq_rpow (x : ℝ≥0∞) (y : ℝ) : ENNReal.rpow' y x = x^y := rfl

theorem ennreal_rpow_of_nnreal (x : ℝ≥0) (y : ℝ)
    : (ENNReal.rpow x y).toNNReal = NNReal.rpow x y := by
  simp only [ENNReal.rpow_eq_pow, NNReal.rpow_eq_pow]
  rw[←ENNReal.toNNReal_rpow]
  simp only [ENNReal.toNNReal_coe]

theorem ennreal_rpow_of_nnreal' (x : ℝ≥0) (y : ℝ) (hynneg : y ≥ 0)
    : ENNReal.rpow x y = ofNNReal (NNReal.rpow x y) := by
  apply (ENNReal.toNNReal_eq_toNNReal_iff' _ _).mp <;> simp
  . rw[←ENNReal.toNNReal_rpow, ENNReal.toNNReal_coe]
  . intro _; assumption

@[fun_prop, measurability]
theorem measurable_NNReal_rpow'_const (c : ℝ) : Measurable (NNReal.rpow' c) := by
  apply Measurable.pow (f := fun x => x) (g := fun _ => c) <;> measurability

@[fun_prop, measurability]
theorem measurable_ENNReal_rpow'_const (c : ℝ) : Measurable (ENNReal.rpow' c) := by
  apply Measurable.pow (f := fun x => x) (g := fun _ => c) <;> measurability

theorem rpow_eq_one_iff (x : ℝ≥0∞) (y : ℝ) (hy : y > 0) : x^y = (1 : ℝ≥0∞) ↔ x = 1 := by
  constructor; swap; intro h; rw[h]; apply ENNReal.one_rpow
  intro h
  rw[←ENNReal.one_rpow y] at h
  apply le_antisymm <;> {apply (ENNReal.rpow_le_rpow_iff hy).mp; rw[h]}

@[simp]
theorem rpow_div_eq_one_iff (x : ℝ≥0∞) (y : ℝ) (hy : y > 0) : x^(1/y) = (1 : ℝ≥0∞) ↔ x = 1 := by
  have : 1/y > 0 := by simp[hy]
  rw[rpow_eq_one_iff x (1/y) this]

lemma toNNReal_of_norm_eq_nnnorm (x : ℝ) : ‖x‖.toNNReal = ‖x‖₊ := by
  calc _ = ‖‖x‖‖₊ := by apply toNNReal_eq_nnnorm_of_nonneg; apply norm_nonneg
       _ = _      := by simp

theorem mul_of_ae_eq {f f' g g' : α → ℝ≥0∞} (hf : f =ᵐ[μ] f') (hg : g =ᵐ[μ] g')
    : f * g =ᵐ[μ] f' * g' := by
  apply ae_iff.mpr
  apply measure_mono_null

  show {a | (f * g) a ≠ (f' * g') a} ⊆ {a | f a ≠ f' a} ∪ {a | g a ≠ g' a}

  . intro a ha
    by_contra!
    aesop
  . apply measure_union_null <;> assumption

theorem mul_of_ae_eq_one (f g: α → ℝ≥0∞) (hf : f =ᵐ[μ] 1) : f * g =ᵐ[μ] g := by
  conv =>
    rhs
    rw[←one_mul g]

  apply mul_of_ae_eq hf
  trivial


end BasicFunctions

theorem integral_mul_le (hpq : p.IsConjExponent q) (μ : Measure α) {f : Lp E₁ p μ} {g : Lp E₂ q μ}
    : ∫ a, ‖L (f a) (g a)‖ ∂μ ≤ ‖L‖ * ‖f‖ * ‖g‖ := by

    have : AEStronglyMeasurable (fun x => L (f x) (g x)) μ :=
                          by apply L.aestronglyMeasurable_comp₂
                             apply (Lp.memℒp f).aestronglyMeasurable
                             apply (Lp.memℒp g).aestronglyMeasurable
    rw[integral_norm_eq_lintegral_nnnorm this]

    have : (‖L‖₊ * (snorm f p μ) * (snorm g q μ)).toReal = ‖L‖ * ‖f‖ * ‖g‖ := by
              calc _ = ‖L‖₊.toReal * (snorm f p μ).toReal * (snorm g q μ).toReal := by simp
                   _ = ‖L‖ * ‖f‖ * ‖g‖                                           := by congr
    rw[←this]

    have : ∫⁻ (a : α), ↑‖(L (f a)) (g a)‖₊ ∂μ
              ≤ ↑‖L‖₊ * snorm (f) p μ * snorm (g) q μ := by apply lintegral_mul_le L hpq μ
                                                            . apply aestronglyMeasurable_iff_aemeasurable.mp
                                                              apply (Lp.memℒp f).aestronglyMeasurable
                                                            . apply aestronglyMeasurable_iff_aemeasurable.mp
                                                              apply (Lp.memℒp g).aestronglyMeasurable
    gcongr
    apply mul_ne_top; apply mul_ne_top
    . simp[this]
    . apply snorm_ne_top f
    . apply snorm_ne_top g

theorem snorm_eq_sup_abs'' {μ : Measure α} (hμ : SigmaFinite μ) (g : Lp ℝ ∞ μ) :
              ‖g‖ = sSup ((fun f => ‖∫ x, (f x) * (g x) ∂μ‖) '' {(f : Lp ℝ 1 μ) | ‖f‖ ≤ 1}) := by
  -- we need μ to be σ-finite
  sorry

def to_conj_of_gt_one_lt_inf' {q : ℝ≥0∞} (g : Lp ℝ q μ) : α → ℝ :=
  fun x => Real.sign (g x) * (ENNReal.rpow' (q.toReal-1) ‖g x‖₊).toReal

def to_conj_of_gt_one_lt_inf {q : ℝ≥0∞} (g : Lp ℝ q μ) : α → ℝ :=
  fun x => (to_conj_of_gt_one_lt_inf' g x) * (NNReal.rpow' (1 - q.toReal) ‖g‖₊)

@[measurability]
theorem conj_of_gt_one_lt_inf'_aestrongly_measurable (g : Lp ℝ q μ)
    : AEStronglyMeasurable (to_conj_of_gt_one_lt_inf' g) μ := by
  apply (aestronglyMeasurable_iff_aemeasurable (μ := μ)).mpr
  unfold to_conj_of_gt_one_lt_inf'
  apply AEMeasurable.mul
  . apply Measurable.comp_aemeasurable'
    . measurability
    . exact (Lp.memℒp g).aestronglyMeasurable.aemeasurable
  . apply Measurable.comp_aemeasurable'
    . measurability
    . apply Measurable.comp_aemeasurable'
      . measurability
      . apply Measurable.comp_aemeasurable'
        . measurability
        . apply Measurable.comp_aemeasurable'
          . measurability
          . exact (Lp.memℒp g).aestronglyMeasurable.aemeasurable

@[measurability]
theorem conj_of_gt_one_lt_inf'_aemeasurable (g : Lp ℝ q μ)
    : AEMeasurable (to_conj_of_gt_one_lt_inf' g) μ := by
  apply (aestronglyMeasurable_iff_aemeasurable (μ := μ)).mp
  exact conj_of_gt_one_lt_inf'_aestrongly_measurable g

@[measurability]
theorem conj_of_gt_one_lt_inf_aestrongly_measurable (g : Lp ℝ q μ)
    : AEStronglyMeasurable (to_conj_of_gt_one_lt_inf g) μ := by
  unfold to_conj_of_gt_one_lt_inf
  apply (aestronglyMeasurable_iff_aemeasurable (μ := μ)).mpr
  apply AEMeasurable.mul <;> measurability

@[measurability]
theorem conj_of_gt_one_lt_inf_aemeasurable (g : Lp ℝ q μ)
    : AEMeasurable (to_conj_of_gt_one_lt_inf g) μ := by
  apply (aestronglyMeasurable_iff_aemeasurable (μ := μ)).mp
  exact conj_of_gt_one_lt_inf_aestrongly_measurable g

theorem snorm'_of_conj_of_gt_one_lt_inf' (g : Lp ℝ q μ) (hqᵢ : q ≠ ∞)
    : snorm' (to_conj_of_gt_one_lt_inf' g) p.toReal μ
    = (snorm' g q.toReal μ) ^ (q.toReal - 1) := by

  unfold snorm'
  rw[←ENNReal.rpow_mul, ←div_conj_exponent'' (q := q) (p := p) hqᵢ]
  rw[←mul_div_right_comm (a := 1) (c := q.toReal)]
  rw[one_mul, div_div, div_mul_cancel_right₀ (hq₀' (p := p) hqᵢ) (a := p.toReal)]
  rw[inv_eq_one_div]
  congr 1

  unfold to_conj_of_gt_one_lt_inf'
  unfold ENNReal.rpow'

  conv =>
    lhs
    pattern _ ^ _
    rw[nnnorm_mul, ENNReal.coe_mul, (ENNReal.mul_rpow_of_nonneg _ _ hp_ge_zero')]
    congr
    rfl
    rw[ENNReal.coe_rpow_of_nonneg _ hp_ge_zero']
    congr
    rw[←Real.toNNReal_eq_nnnorm_of_nonneg toReal_nonneg]
    rw[toNNReal_eq_toNNreal_of_toReal, ENNReal.toNNReal_rpow]
    congr
    dsimp [ENNReal.rpow]
    rw[←ENNReal.rpow_mul]
    congr
    rfl
    rw[sub_mul (c := p.toReal), one_mul, mul_comm, ←add_conj_exponent' hqᵢ]
    simp
    rfl

  conv =>
    lhs
    pattern _*_
    congr

    . rw[rpow_of_nnnorm_of_sign _ _ hp_gt_zero']
      rfl

    . rw[ENNReal.coe_toNNReal]
      rfl
      apply ENNReal.rpow_of_NNReal_ne_top _ _ hq_ge_zero'

  apply lintegral_congr_ae
  apply ae_iff.mpr
  simp_all

  conv =>
    lhs
    pattern _ ^ _
    rw[ENNReal.zero_rpow_of_pos (hq_gt_zero' hqᵢ)]
    rfl

  simp

def to_conj₁ (g : Lp ℝ 1 μ) : α → ℝ := fun x => Real.sign (g x)

theorem conj₁_aestrongly_measurable (g : Lp ℝ 1 μ) : AEStronglyMeasurable (to_conj₁ g) μ := by
  apply (aestronglyMeasurable_iff_aemeasurable (μ := μ)).mpr
  apply Measurable.comp_aemeasurable' (f := g)
  . apply measurable_sign
  . apply aestronglyMeasurable_iff_aemeasurable.mp
    exact (Lp.memℒp g).aestronglyMeasurable

-- def to_conj (g : Lp ℝ q μ) : α → ℝ := if q = 1 then to_conj₁ g else to_conjᵢ g

theorem abs_conj₁ (g : Lp ℝ 1 μ) (x) : |to_conj₁ g x| = if g x = 0 then 0 else 1 := by
  apply abs_of_sign

variable (p q μ) in
theorem snorm_eq_sup_abs' (g : Lp ℝ q μ) (hqᵢ : q ≠ ∞) :
              ‖g‖ = sSup ((fun f => ‖∫ x, (f x) * (g x) ∂μ‖) '' {(f : Lp ℝ p μ) | ‖f‖ ≤ 1}) := by
  -- basic facts about p and q
  have hpq := hpq.out

  have hp := hp.out
  have h'p := h'p.out
  have hpᵢ : p ≠ ∞ := by apply lt_top_iff_ne_top.mp h'p
  have hp₀ : p ≠ 0 := by have := by calc 0 < 1   := by norm_num
                                         _ ≤ p   := hp
                         apply ne_zero_of_lt this
  have hq := hq.out
  -- let h'q := h'q.out
  -- let hqᵢ : q ≠ ∞ := by apply lt_top_iff_ne_top.mp h'q
  have hq₀ : q ≠ 0 := by have := by calc 0 < 1   := by norm_num
                                         _ ≤ q   := hq
                         apply ne_zero_of_lt this

  -- construction of the function f₀'
  let F := (fun f : Lp ℝ p μ => ‖∫ x, (f x) * (g x) ∂μ‖)
  let S := {f : Lp ℝ p μ | ‖f‖ ≤ 1}

  #check integral_congr_ae

  apply le_antisymm; swap
  . apply Real.sSup_le; swap; apply norm_nonneg
    intro x hx
    rcases hx with ⟨f, hf, rfl⟩
    simp at hf; dsimp only

    calc _ ≤ ∫ x, ‖f x * g x‖ ∂μ             := by apply norm_integral_le_integral_norm
         _ = ∫ x, ‖(mul ℝ ℝ) (f x) (g x)‖ ∂μ := by simp
         _ ≤ ‖(mul ℝ ℝ)‖ * ‖f‖ * ‖g‖         := by apply integral_mul_le; exact hpq
         _ = ‖f‖ * ‖g‖                       := by simp
         _ ≤ 1 * ‖g‖                         := by gcongr
         _ = ‖g‖                             := by simp

  --
  . let h₁ := fun (y : ℝ) => y^(q.toReal-1)
    have h₁_cont : Continuous h₁ := by dsimp only [h₁]
                                       apply Continuous.rpow_const
                                       apply continuous_id
                                       intro _; right; simp;
                                       rw[←ENNReal.one_toReal]
                                       gcongr
                                       exact hqᵢ

    let h₂ := fun (y : ℝ) => h₁ (abs y)
    have h₂_cont : Continuous h₂ := by apply Continuous.comp';
                                       apply h₁_cont;
                                       apply Continuous.abs;
                                       apply continuous_id

    let h := fun (y : ℝ) => (Real.sign y) * (h₂ y) * ‖g‖^(q.toReal-1)
    let f₀ := fun (x : α) => h (g x)

    have h_meas : Measurable h := by apply Measurable.mul; swap
                                     . apply measurable_const
                                     . apply Measurable.mul
                                       . apply measurable_sign
                                       . apply Continuous.measurable; apply h₂_cont

    have hf₀_meas : AEStronglyMeasurable f₀ μ := by apply aestronglyMeasurable_iff_aemeasurable.mpr
                                                    dsimp[f₀]
                                                    apply Measurable.comp_aemeasurable' (f := g) (g := h)
                                                    . exact h_meas
                                                    . apply aestronglyMeasurable_iff_aemeasurable.mp
                                                      exact (Lp.memℒp g).aestronglyMeasurable

    #check integral_norm_eq_lintegral_nnnorm hf₀_meas
    #check (rpow_left_inj _ _ _).mp

    have hf_snorm : snorm f₀ p μ = 1 := by simp[snorm, hp₀, hpᵢ]
                                           dsimp only [snorm']
                                            -- should be easy
                                           sorry

    have hf_memℒp : Memℒp f₀ p μ := by constructor
                                       . exact hf₀_meas
                                       . simp[hf_snorm]

    let f₀' := by apply toLp f₀
                  . constructor
                    . exact hf₀_meas
                    . apply lt_of_le_of_lt
                      . show snorm f₀ p μ ≤ 1
                        simp only [hf_snorm, le_refl]
                      . simp only [one_lt_top]

    have hf₀'_norm : ‖f₀'‖ = 1 := by sorry
    have hf₀'_int : ∫ x, (f₀' x) * (g x) ∂μ = ‖g‖ := by sorry

    . apply le_csSup
      . use ‖g‖
        intro x hx
        rcases hx with ⟨f, hf, rfl⟩
        simp at hf

        calc _ ≤ ∫ x, ‖f x * g x‖ ∂μ             := by apply norm_integral_le_integral_norm
            _ = ∫ x, ‖(mul ℝ ℝ) (f x) (g x)‖ ∂μ := by simp
            _ ≤ ‖(mul ℝ ℝ)‖ * ‖f‖ * ‖g‖         := by apply integral_mul_le; exact hpq
            _ = ‖f‖ * ‖g‖                       := by simp
            _ ≤ 1 * ‖g‖                         := by gcongr
            _ = ‖g‖                             := by simp
        -- this is duplicate code

      . use f₀'
        constructor
        . simp only [Set.mem_setOf_eq]; rw[hf₀'_norm]
        . dsimp only; rw[hf₀'_int]; simp only [norm_norm]

variable (p q μ) in
theorem snorm_eq_sup_abs (hμ : SigmaFinite μ) (g : Lp ℝ q μ):
              ‖g‖ = sSup ((fun f => ‖∫ x, (f x) * (g x) ∂μ‖) '' {(f : Lp ℝ p μ) | ‖f‖ ≤ 1}) := by

  by_cases hqᵢ : q ≠ ⊤; swap
  . simp at hqᵢ
    have hp₁ : p = 1 := by {
      rw[left_eq_one_iff, ← hqᵢ]
      exact hpq.out
    }
    subst hqᵢ; subst hp₁
    sorry
  . sorry

  --   apply snorm_eq_sup_abs'' μ hμ g

  -- . apply snorm_eq_sup_abs' p q μ g hqᵢ

/- The map sending `g` to `f ↦ ∫ x, L (g x) (f x) ∂μ` induces a map on `L^q` into
`Lp E₂ p μ →L[ℝ] E₃`. Generally we will take `E₃ = ℝ`. -/
variable (p μ) in
def toDual (g : Lp E₁ q μ) : Lp E₂ p μ →L[ℝ] E₃ := by{

  let F : Lp E₂ p μ → E₃ := fun f ↦ ∫ x, L (g x) (f x) ∂μ

  have : IsBoundedLinearMap ℝ F := by{
    exact {
      map_add := by{
        intro f₁ f₂
        simp[F]
        rw[← integral_add]
        · apply integral_congr_ae
          filter_upwards [coeFn_add f₁ f₂] with a ha
          norm_cast
          rw[ha]
          simp
        · exact ENNReal.IsConjExponent.integrable_bilin L hpq.out.symm μ (Lp.memℒp g) (Lp.memℒp f₁)
        · exact ENNReal.IsConjExponent.integrable_bilin L hpq.out.symm μ (Lp.memℒp g) (Lp.memℒp f₂)
        }

      map_smul := by{
        intro m f
        simp[F]
        rw[← integral_smul]
        apply integral_congr_ae
        filter_upwards [coeFn_smul m f] with a ha
        rw[ha]
        simp
        }

      bound := by{
        suffices henough : ∃ M, ∀ (x : ↥(Lp E₂ p μ)), ‖F x‖ ≤ M * ‖x‖ from ?_
        . let ⟨M, hM⟩ := henough; clear henough

          by_cases hM_le_zero : M ≤ 0
          . use 1; constructor; linarith; intro f
            calc ‖F f‖ ≤ M * ‖f‖ := hM f
                 _     ≤ 1 * ‖f‖ := by apply mul_le_mul_of_nonneg_right; linarith
                                       apply norm_nonneg
          . simp at hM_le_zero; use M

        simp only [F]
        use ‖L‖ * ‖g‖
        intro f
        calc ‖∫ (x : α), (L (g x)) (f x) ∂μ‖ ≤ ∫ (x : α), ‖L (g x) (f x)‖ ∂μ := by apply norm_integral_le_integral_norm
             _ ≤ ‖L‖ * ‖g‖ * ‖f‖ := ?_

        apply integral_mul_le L hpq.out.symm
      }
    }
  }

  apply IsBoundedLinearMap.toContinuousLinearMap this
}

/- The map sending `g` to `f ↦ ∫ x, (f x) * (g x) ∂μ` is a linear isometry. -/
variable (L' : ℝ →L[ℝ] ℝ →L[ℝ] ℝ) (L'mul : ∀ x y, L' x y = x * y) (L'norm_one : ‖L'‖ = 1) in
def toDualₗᵢ' : Lp ℝ q μ →ₗᵢ[ℝ] Lp ℝ p μ →L[ℝ] ℝ where
  toFun := toDual _ _ L'
  map_add':= by{
    intro g₁ g₂
    simp[toDual, IsBoundedLinearMap.toContinuousLinearMap, IsBoundedLinearMap.toLinearMap]
    ext f
    simp
    rw[← integral_add]
    · apply integral_congr_ae
      filter_upwards [coeFn_add g₁ g₂] with a ha
      norm_cast
      rw[ha]
      simp
    · exact ENNReal.IsConjExponent.integrable_bilin L' hpq.out.symm μ (Lp.memℒp g₁) (Lp.memℒp f)
    · exact ENNReal.IsConjExponent.integrable_bilin L' hpq.out.symm μ (Lp.memℒp g₂) (Lp.memℒp f)
  }
  map_smul':= by{
    intro m g
    simp[toDual, IsBoundedLinearMap.toContinuousLinearMap, IsBoundedLinearMap.toLinearMap]
    ext f
    simp
    rw[← integral_mul_left] -- mul vs smul
    apply integral_congr_ae
    filter_upwards [coeFn_smul m g] with a ha
    rw[ha]
    simp[L'mul]; ring
  }
  norm_map' := by {
    intro g
    conv_lhs => simp[Norm.norm]
    apply ContinuousLinearMap.opNorm_eq_of_bounds
    . simp
    . intro f
      calc ‖(toDual p μ L' g) f‖ ≤ ∫ x, ‖L' (g x) (f x)‖ ∂μ := by apply norm_integral_le_integral_norm
           _ ≤ ‖L'‖ * ‖g‖ * ‖f‖ := by apply integral_mul_le L' hpq.out.symm
           _ = ‖g‖ * ‖f‖ := by simp[L'norm_one]
           _ = _ := by aesop
    . intro N Nnneg
      intro hbound


      let f := fun (x : α) => (Real.sign (g x))

      -- #check snorm'_lim_eq_lintegral_liminf
      sorry
      -- f = g ^ q-1 have := hbound

    -- apply le_antisymm
    -- . apply ContinuousLinearMap.opNorm_le_bound; apply norm_nonneg
    --   intro f
    --   simp
    --   calc ‖(toDual p μ L' g) f‖ = ‖∫ x, L' (g x) (f x) ∂μ‖ := by congr
    --        _ ≤ ∫ x, ‖L' (g x) (f x)‖ ∂μ := by apply norm_integral_le_integral_norm
    --        _ ≤ ‖L'‖ * ‖g‖ * ‖f‖ := by apply integral_mul_le; exact hpq.out.symm
    --        _ = ‖g‖ * ‖f‖ := by simp[L'norm_one]

    -- . simp[Norm.norm, ContinuousLinearMap.opNorm]
    --   -- apply UniformSpace.le_sInf (α := ℝ)
    --   -- #check (@sInf ℝ).le
    --   sorry
  }

/- The map sending `g` to `f ↦ ∫ x, L (f x) (g x) ∂μ` is a linear isometry. -/
variable (p q μ) in
def toDualₗᵢ : Lp E₁ q μ →ₗᵢ[ℝ] Lp E₂ p μ →L[ℝ] E₃ where

  toFun := toDual _ _ L
  map_add':= by{
    intro g₁ g₂
    simp[toDual, IsBoundedLinearMap.toContinuousLinearMap, IsBoundedLinearMap.toLinearMap]
    ext f
    simp
    rw[← integral_add]
    · apply integral_congr_ae
      filter_upwards [coeFn_add g₁ g₂] with a ha
      norm_cast
      rw[ha]
      simp
    · exact ENNReal.IsConjExponent.integrable_bilin L hpq.out.symm μ (Lp.memℒp g₁) (Lp.memℒp f)
    · exact ENNReal.IsConjExponent.integrable_bilin L hpq.out.symm μ (Lp.memℒp g₂) (Lp.memℒp f)
  }
  map_smul':= by{
    intro m g
    simp[toDual, IsBoundedLinearMap.toContinuousLinearMap, IsBoundedLinearMap.toLinearMap]
    ext f
    simp
    rw[← integral_smul]
    apply integral_congr_ae
    filter_upwards [coeFn_smul m g] with a ha
    rw[ha]
    simp
  }
  norm_map' := by {
    sorry
  }

/- The map sending `g` to `f ↦ ∫ x, L (f x) (g x) ∂μ` is a linear isometric equivalence.  -/
variable (p q μ) in
def dualIsometry (L : E₁ →L[ℝ] Dual ℝ E₂) :
    Dual ℝ (Lp E₂ p μ) ≃ₗᵢ[ℝ] Lp E q μ :=
  sorry

end Lp
end MeasureTheory


end
