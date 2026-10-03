/* Obfuscation of the public key for BLS12-479+ using Elligator Squared (2-Isogeny Bridge) */

p := 1040582850105330743815570414239668597581975900197275493095847470017583224665441180782578049215009464174278151947833029365685675660572997417552727;
Fp := FiniteField(p);

B_target := Fp!1;
A_isog   := Fp!-15;
B_isog   := Fp!22;

E_target := EllipticCurve([Fp | 0, B_target]);
E_isog   := EllipticCurve([Fp | A_isog, B_isog]);
Identity := E_target!0;

// Dual Isogeny mapping (E' -> E) + Isomorphism
function Isogeny2Target(P_isog)
    if P_isog eq E_isog!0 then return Identity; end if;
    x := P_isog[1]; y := P_isog[2];
    
    x_den := x - 2; // Kernel of dual isogeny is x'_0 = 2
    if x_den eq 0 then return Identity; end if;
    
    // Velu to E'': y^2 = x^3 + 64 (where t' = -3)
    X_isog := x - 3 / x_den;
    Y_isog := y + 3 * y / (x_den^2);
    
    // Isomorphism to E_target: y^2 = x^3 + 1 (scaling by u^2=4, u^3=8)
    return E_target![X_isog / 4, Y_isog / 8];
end function;

// Inverse of Dual Isogeny (solving quadratic for Obfuscation)
function BasePreimage(P_target)
    x_t := P_target[1];
    
    // Solves (x')^2 - (4*x_t + 2)*x' + (8*x_t - 3) = 0
    B_coef := -(4 * x_t + 2);
    C_coef := 8 * x_t - 3;
    Delta := B_coef^2 - 4*C_coef;
    
    if not IsSquare(Delta) then return false, Fp!0; end if;
    root := Sqrt(Delta);
    return true, (-B_coef + root) / 2; 
end function;

function GenerateAndObfuscateOnIsog(P_isog)
    P_target := Isogeny2Target(P_isog);
    Success, x_cand := BasePreimage(P_target);
    
    if not Success then
        return false, Fp!0, Fp!0;
    end if;
    
    // Reconstruct the y-coordinate on E_isog: y^2 = x^3 + A*x + B
    y_sq := x_cand^3 + A_isog * x_cand + B_isog;
    y_cand := Sqrt(y_sq);
    
    return true, x_cand, y_cand;
end function;

function ReconstructAndMap2Target(u, v)
    P_isog_rec := E_isog![u, v];
    return Isogeny2Target(P_isog_rec);
end function;


print "\n--- Correctness Verification ---";
// Find a random point for which a preimage exists (simulating Rejection Sampling)
Success := false;
PublicKey_isog := Identity;
u := Fp!0; v := Fp!0;

while not Success do
    PublicKey_isog := Random(E_isog);
    if PublicKey_isog eq Identity then continue; end if;
    Success, u, v := GenerateAndObfuscateOnIsog(PublicKey_isog);
end while;

Expected_PublicKey_target := Isogeny2Target(PublicKey_isog);
Recovered_PublicKey_target := ReconstructAndMap2Target(u, v);

printf "Expected   : %o\n", Expected_PublicKey_target;
printf "Recovered  : %o\n", Recovered_PublicKey_target;

// Verification check for the reconstructed point
// Checking the correctness of the recovery (taking into account the sign of Y)
assert Recovered_PublicKey_target eq Expected_PublicKey_target or \
       Recovered_PublicKey_target eq -Expected_PublicKey_target;
print "Assert passed! The point was successfully reconstructed.";


print "\n--- Runtime Test & Benchmark ---";
printf "Target Curve:    %o\n", E_target;
printf "Isogenous Curve: %o\n", E_isog;
printf "Running 100000 iterations for 2-Isogeny Obfuscation...\n";

NumberOfAttempts := 100000; 
ObfuscateCls := 0;  
DeObfuscateCls := 0; 

for i in [1..NumberOfAttempts] do
    // Profile obfuscation clock cycles
    t_time := ClockCycles(); 
    _, u, v := GenerateAndObfuscateOnIsog(PublicKey_isog);
    ObfuscateCls +:= (ClockCycles() - t_time);

    // Profile deobfuscation clock cycles
    t_time := ClockCycles(); 
    PublicKey_target := ReconstructAndMap2Target(u, v);
    DeObfuscateCls +:= (ClockCycles() - t_time);
end for;

print "\n__________________ Clock cycles (BLS12-479+ 2-Isogeny) ___________________";
print " \nObfuscation:  ", ObfuscateCls div NumberOfAttempts;
print " \nDeobfuscation:", DeObfuscateCls div NumberOfAttempts;
quit;
