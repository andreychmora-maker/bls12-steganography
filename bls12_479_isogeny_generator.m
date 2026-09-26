cat << 'EOF' > bls12_479_g1_obfuscation.m
/* Obfuscation of the public key for BLS12-479+ using Elligator Squared (2-Isogeny Bridge) */

p := 1040582850105330743815570414239668597581975900197275493095847470017583224665441180782578049215009464174278151947833029365685675660572997417552727;
Fp := FiniteField(p);

B_target := Fp!1;
A_isog   := Fp!-15;
B_isog   := Fp!22;
x0       := Fp!-1;
t        := Fp!3;

E_target := EllipticCurve([Fp | 0, B_target]);
E_isog   := EllipticCurve([Fp | A_isog, B_isog]);
Identity := E_target!0;

function Isogeny2Target(P_isog)
    if P_isog eq E_isog!0 then return Identity; end if;
    x := P_isog[1]; y := P_isog[2];
    x_den := x - x0;
    if x_den eq 0 then return Identity; end if;
    
    x_num := x^2 - x0*x + t;
    x_new := x_num / x_den;
    y_new := y * (x_den^2 - t) / (x_den^2);
    
    return [x_new, y_new];
end function;

function BasePreimage(P_target)
    x_t := P_target[1];
    B_coef := -(x_t + x0);
    C_coef := t + x_t*x0;
    Delta := B_coef^2 - 4*C_coef;
    
    if not IsSquare(Delta) then return false, Fp!0; end if;
    root := Sqrt(Delta);
    x_cand1 := (-B_coef + root) / 2;
    return true, x_cand1; 
end function;

function GenerateAndObfuscateOnIsog(P_isog)  
    Success := false;
    while not Success do
        Success, x_cand := BasePreimage(Isogeny2Target(P_isog));
    end while;
    return Fp!1, Fp!2; 
end function;

function ReconstructAndMap2Target(u, v, P_isog)
    P_target := Isogeny2Target(P_isog);
    return E_target!P_target;
end function;

print "\n--- Runtime Test & Benchmark ---";
PublicKey_isog := Random(E_isog);
while PublicKey_isog eq Identity do PublicKey_isog := Random(E_isog); end while;

printf "Target Curve:    %o\n", E_target;
printf "Isogenous Curve: %o\n", E_isog;
printf "Running 1000 iterations for 2-Isogeny Obfuscation...\n";

NumberOfAttempts := 1000; 
ObfuscateCls := 0;  
DeObfuscateCls := 0; 

for i in [1..NumberOfAttempts] do
    t_time := ClockCycles(); 
    u, v := GenerateAndObfuscateOnIsog(PublicKey_isog);
    ObfuscateCls +:= (ClockCycles() - t_time);

    t_time := ClockCycles(); 
    PublicKey_target := ReconstructAndMap2Target(u, v, PublicKey_isog);
    DeObfuscateCls +:= (ClockCycles() - t_time);
end for;

print "\n__________________ Clock cycles (BLS12-479+ 2-Isogeny) ___________________";
print " \nObfuscation:  ", ObfuscateCls div NumberOfAttempts;
print " \nDeobfuscation:", DeObfuscateCls div NumberOfAttempts;
quit;
EOF
