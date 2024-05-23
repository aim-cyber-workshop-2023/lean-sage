import Mathlib
import LeanSage.ForMathlib

/-- Call `sage` -/
def sageOutput (args : Array String) : IO String := do
  IO.Process.run { cmd := "sage", args := args }

/-- Parse a string containing a list of integers. Should be a proper parser! -/
def String.parseNatList (l : String) : List ℕ :=
  (((l.drop 1).dropRight 2).split (. = ' ')).map
    (fun s => s.stripSuffix ",") |> .map String.toNat!

/-- An "unsafe" function that calls `sage` to find the prime factors of a number. -/
unsafe def sagePrimeFactorsUnsafe (n : ℕ) : List ℕ :=
  let args := #["-c", s!"print(prime_factors({n}))"] ;
  match unsafeBaseIO (sageOutput args).toBaseIO with
  | .ok l => l.parseNatList
  | .error _ => []

/--
An "opaque" wrapper around the unsafe function.

This prevents the `unsafe` label propagating to definitions that use it,
but also prevent Lean from knowing anything about the implementation.
-/
@[implemented_by sagePrimeFactorsUnsafe]
opaque sagePrimeFactors (n : ℕ) : List ℕ

def p := 22801763489

/-- info: [2, 7, 47, 309403] -/
#guard_msgs in
#eval sagePrimeFactors (p - 1)

/-!
# We could provide a verified wrapper.
-/

def rdiv (n : ℕ) (m : ℕ) : ℕ := if n % m = 0 then rdiv (n / m) m else n
decreasing_by sorry

def rdiv' (n : ℕ) (ms : List ℕ) : ℕ := ms.foldl rdiv n

def safePrimeFactors (n : ℕ) : Finset ℕ :=
  let candidates := sagePrimeFactors n
  if candidates.all Nat.Prime && rdiv' n candidates = 1 then
    candidates.toFinset
  else
    Nat.primeFactors n

theorem safePrimeFactors_eq_primeFactors {n : ℕ} : safePrimeFactors n = Nat.primeFactors n := by
  dsimp [safePrimeFactors]
  split
  · rename_i h
    simp at h
    sorry
  · rfl

/-!
# Or just axiomatize it, and build on top!
-/

/-- An axiom specifying the behaviour of `sagePrimeFactors`. -/
@[simp] axiom mem_sagePrimeFactors_iff {p n : ℕ} :
    p ∈ sagePrimeFactors n ↔ p ∈ Nat.primeFactors n

/--
Now define our new algorithm.

Note this is an algorithm: it return a `Bool` not a `Prop`, and is computable:
-/
def sageIsPrimitiveRoot (a : ℕ) (p : ℕ) : Bool :=
  (a : ZMod p) != 0 && (sagePrimeFactors (p - 1)).all fun q => (a ^ ((p - 1) / q) : ZMod p) != 1

#guard !sageIsPrimitiveRoot 2 p
#guard sageIsPrimitiveRoot 11 p

/--
Now we verify that that this algorithm has the expected behaviour by relating it
to existing formalized notions in Mathlib.

Here Mathlib's `IsPrimitiveRoot x k` asserts that
`a` is a primitive root of unity of order `k` in some commutative monoid.
-/
theorem IsPrimitiveRoot_iff_sageIsPrimitiveRoot {p : ℕ} [Fact (p.Prime)] (a : (ZMod p)ˣ) :
    IsPrimitiveRoot a (p - 1) ↔ sageIsPrimitiveRoot a.val.val p := by
  -- This proof relies on several theorems in another file,
  -- that properly belong in Mathlib (soon!).
  simp [IsPrimitiveRoot_zmod_iff, sageIsPrimitiveRoot]
  norm_cast
  simp only [Units.val_eq_one]

#print axioms IsPrimitiveRoot_iff_sageIsPrimitiveRoot -- includes `mem_sagePrimeFactors_iff`
