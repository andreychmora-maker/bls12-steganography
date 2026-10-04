p := 1199710345211519035416219429741786876319311421933497483626991418658478319088544596915796254702839442454587420641007826572438113715342206999017869775578752368205297;
x := 1237940039285380274899137265;

/* Expected order of the BLS12 curve: n = p + 1 - t, where t = x + 1 */
target_order := p - x; 

Fp := GaloisField(p);
B_found := 0;

print "Searching for B...";
for B_val in [1..100] do
    /* Check positive B */
    E := EllipticCurve([Fp | 0, B_val]);
    P := Random(E);
    if target_order * P eq E!0 then
        B_found := B_val;
        break;
    end if;
    
    /* Check negative B */
    E_neg := EllipticCurve([Fp | 0, -B_val]);
    P_neg := Random(E_neg);
    if target_order * P_neg eq E_neg!0 then
        B_found := -B_val;
        break;
    end if;
end for;

printf "==================================================\n";
printf "Optimal B parameter for BLS12-539 : %o\n", B_found;
printf "==================================================\n";
