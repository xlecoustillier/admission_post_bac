/* Code fourni, lignes 48 à 96 */
-- classement aléatoire sur voeu 1 groupé relatif

CURSOR classement_aleatoire_efe IS
-- on traite d'abord les candidats AEFE s'il y en a
SELECT c.g_cn_cod,

a_ve_ord_vg_rel, -- Ordre du voeu avec voeux groupés relatifs licence
a_ve_ord_aff,    -- Ordre du voeu avec voeux groupé relatif licence et tous les autres voeux
a_vg_ord,        -- Ordre du sous-voeu dans le voeu groupé
DBMS_RANDOM.value(1,999999),
i.i_ep_cod

FROM g_can c, i_ins i, a_rec r, a_voe v
WHERE i.g_ti_cod=o_g_ti_cod
AND g_gf_cod=o_c_gp_cod
AND i.g_cn_cod=c.g_cn_cod
AND c.g_ic_cod > 0
AND NVL(g_cn_flg_aefe, 0)=1 -- Bac EFE
AND i_ep_cod IN (2, 3)      -- Pointés recu (complet ou incomplet)
AND i.i_is_val=1            -- non encore classé
AND NOT EXISTS (SELECT 1 FROM c_can_grp
  WHERE i.g_cn_cod=g_cn_cod
  AND i.g_gf_cod=c_gp_cod
  AND i_ip_cod IN (4, 5))          -- Permet de récupérer les AC
AND i.g_ti_cod=r.g_ti_cod
AND c.g_cn_cod=v.g_cn_cod
AND r.g_ta_cod=v.g_ta_cod
UNION
-- les candidats EFE qui n'ont au final pas classé la formation dans leur liste ordonnée. Ils sont classé, mais en dernier.
SELECT c.g_cn_cod,
0,
0,
0,
DBMS_RANDOM.value(1,999999),
i.i_ep_cod
FROM g_can c, i_ins i, a_rec r
WHERE i.g_ti_cod=o_g_ti_cod
AND g_gf_cod=o_c_gp_cod
AND i.g_cn_cod=c.g_cn_cod
AND c.g_ic_cod > 0
AND NVL(g_cn_flg_aefe, 0)=1 -- BaC EFE
AND i_ep_cod IN (2, 3)      -- Pointés recu (complet ou incomplet)
AND i.i_is_val=1            -- non encore classé
-- non encore classé
AND NOT EXISTS (SELECT 1 FROM c_can_grp
  WHERE i.g_cn_cod=g_cn_cod
  AND i.g_gf_cod=c_gp_cod
  AND i_ip_cod IN (4, 5))   -- Permet de récupérer les AC
AND i.g_ti_cod=r.g_ti_cod
AND NOT EXISTS (SELECT 1 FROM a_voe v WHERE c.g_cn_cod=v.g_cn_cod AND r.g_ta_cod=v.g_ta_cod)
ORDER BY 2, 3, 4, 5;

/* Code mis en forme :
Il paraît plus simple de faire un LEFT JOIN sur la table a_voe, et de mettre certaines valeurs à 0 lorsque la jointure ne s'est pas faite */
-- DO NOT USE !!!
-- classement aléatoire sur voeu 1 groupé relatif
CURSOR classement_aleatoire_efe IS
-- on traite d'abord les candidats AEFE s'il y en a
SELECT candidat.g_cn_cod,
	IFNULL(voeu.g_cn_cod, 0, voeu.a_ve_ord_vg_rel), -- Ordre du voeu avec voeux groupés relatifs licence, 0 si pas de voeu
	IFNULL(voeu.g_cn_cod, 0, voeu.a_ve_ord_aff), -- Ordre du voeu avec voeux groupé relatif licence et tous les autres voeux, 0 si pas de voeu
	IFNULL(voeu.g_cn_cod, 0, voeu.a_vg_ord), -- Ordre du sous-voeu dans le voeu groupé, 0 si pas de voeu
	DBMS_RANDOM.value(1,999999),
	i.i_ep_cod
FROM g_can candidat
INNER JOIN i_ins i ON i.g_cn_cod=candidat.g_cn_cod
INNER JOIN a_rec r ON i.g_ti_cod=r.g_ti_cod
LEFT JOIN a_voe voeu ON candidat.g_cn_cod=voeu.g_cn_cod AND r.g_ta_cod=voeu.g_ta_cod
WHERE 
	i.g_ti_cod=o_g_ti_cod
	AND i.g_gf_cod=o_c_gp_cod
	AND candidat.g_ic_cod > 0
	AND NVL(g_cn_flg_aefe, 0)=1 -- Bac EFE
	AND i_ep_cod IN (2, 3) -- Pointés recu (complet ou incomplet)
	AND i.i_is_val=1 -- non encore classé
	AND NOT EXISTS (
		SELECT 1 FROM c_can_grp
		WHERE i.g_cn_cod=g_cn_cod
		AND i.g_gf_cod=c_gp_cod
		AND i_ip_cod IN (4, 5)
	) -- Permet de récupérer les AC
ORDER BY 2, 3, 4, 5;
		
/* 
NOTE : la fonction de la table a_rec reste à préciser.

Explication détaillée :
Il s'agit de construire un curseur sur un ensemble de candidats (g_can), inscriptions à des formations (i_ins), a_rec (?), voeux (a_voe) reliés entre eux.
IL FAUT PRÊTER ATTENTION AU FAIT QUE LES CANDIDATS SONT FILTRÉS À CE NIVEAU POUR DÉTERMINER CEUX POUR LESQUELS LE TRAITEMENT SUIVANT (ATTRIBUTION D'UN RANG) AURA LIEU.

Explication préliminaire
------------------------
Le code suivant est utilisé 4 fois (2 fois ici et 2 fois plus loin). C'EST UN FILTRE SUR LES CANDIDATS POUR LESQUELS LE TRAITEMENT AURA LIEU :

NOT EXISTS (SELECT 1 FROM c_can_grp
WHERE i.g_cn_cod=g_cn_cod,
AND i.g_gf_cod=c_gp_cod
AND i_ip_cod IN (4, 5))

La table "c_can_grp" contient la relation entre les candidats et les groupes. Si elle contient une correspondance entre notre groupe et un candidat avec un c_can_grp.i_ip_cod  valant 4 (NC = non classé) ou 5 (C = classé), c'est que ce candidat est déjà passé par les étapes suivantes (voir lignes 269 et suivantes). Un candidat pour lequel il existe une correspondance candidat-groupe mais pour lequel i_ip_cod vaut 6 (AC = à classer) est conservé.

>> Le code précédent exclut donc les candidats pour lesquels il y a eu affectation d'un rang dans un groupe, sauf s'ils sont encore "à classer".

La relation entre candidats, inscriptions, reçus, voeux
-------------------------------------------------------
On cherche, pour chaque candidat, une inscription (i.g_cn_cod=c.g_cn_cod) à une formation qui correspond à une ligne de la table a_rec (établissement ??) (i.g_ti_cod=r.g_ti_cod), puis on cherche d'éventuels voeux de ce candidat (c.g_cn_cod=v.g_cn_cod).

Critères pour le filtre sur les candidats pour lesquels le traitement aura lieu
--------------------------------------------------------------------------------------
Les codes i_ins.g_ti_cod et i_ins.g_gf_cod correspondent aux paramètres o_g_ti_cod (formation visée) et o_c_gp_cod (groupe des candidats) de l'appel de la fonction. 
En plus des condtions précédentes, il faut qu'on trouve une inscription de ce candidat, à la formation (DETAILLER).

On retient (et ne retient que) les inscriptions dont le groupe et la formation correspondent. Le lien avec le candidat se fait sur le g_cn_cod.

Les condition sont cumulatives :
* g_can.g_ic_cod > 0 : ?? ;
* NVL(g_cn_flg_aefe, 0)=1 : le commentaire indique un bac EFE. g_cn_flg_aefe doit probablement appartenir à la table g_can ;
* i_ep_cod IN (2, 3) : le commentaire indique pointés recu (complet ou incomplet). i_ep_cod doit probablement appartenir à la table i_ins ;
* i.i_is_val=1 : le commentaire indique non encore classé. Même table. Mais la valeur n'est pas mise à jour dans le code fourni.
* pas un candidat déjà passé par la moulinette des lignes 269 et suivantes.

Résumé : il faut cumuler une inscription à la formation et au groupe paramètres de la fonction, ne pas être déjà passé à la moulinette, deux conditions de forme (g_ic_cod > 0 et i_is_val=1) et surtout un Bac EFE et être pointé-reçu.

Le point surprenant est qu'on ne voit pas la mise à jour de i_is_val dans le code.

Ordre de sélection des candidats
--------------------------------
ATTENTION, IL NE S'AGIT PAS DU RANG ATTRIBUE, MAIS D'UNE OPERATION PREALABLE.

Ce sont les ordres de voeux, du plus petit au plus grand numéro d'ordre. Les voeux ayant un numéro 0 sont les derniers, ce qui tend à montrer que les numéros d'ordre sont négatifs (??). Le tri est fait en comparant les candidats un à un selon les règles suivantes :
* le plus petit voeu.a_ve_ord_vg_rel est premier ;
* si voeu.a_ve_ord_vg_rel est identique, le plus petit voeu.a_ve_ord_aff est premier ;
* si voeu.a_ve_ord_vg_rel et voeu.a_ve_ord_aff sont identiques, le plus petit voeu.a_vg_ord est premier ;
* si voeu.a_ve_ord_vg_rel, voeu.a_ve_ord_aff et voeu.a_vg_ord sont identiques, un tirage au sort départage les candidats.

Les commentaires et le document transmis par l'EN en mai 2016 permettent de conclure que :
* voeu.a_ve_ord_vg_rel est le numéro d'ordre du voeu par rapport aux autres voeux groupés licence (= voeu portant sur une filière et une académie) ;
* voeu.a_ve_ord_aff est le numéro d'ordre absolu du voeu par rapport aux autres voeux groupés licence ;
* voeu.a_vg_ord est le numéro d'ordre du voeu dans le groupe formé par le voeu groupé.

POINTS A NOTER : 
1. puisque les valeurs de l'ordre des voeux (voeu.a_ve_ord_vg_rel, voeu.a_ve_ord_aff, voeu.a_vg_ord) sont inscrites dans la table a_voe, RIEN N'EMPECHE QUE DES INCOHERENCES APPARAISSENT DANS LA BASE. On n'a pas la sécurité d'un AUTO INCREMENT sur une table de relation entre candidats et voeux qui viendrait en bout de course pour éviter qu'un candidat ait plusieurs voeux n°1. Par ailleurs, le modèle possède d'autres champs concernant l'ordre du voeu, ici inutilisés, qu'il serait intéressant de connaître.
2. Le nombre aléatoire n'est pas stocké mais généré à chaque passage. Impossible donc pour un candidat de savoir quel nombre le sort lui a accordé (problème de contrôle a posteriori ?).
3. Il peut y avoir collision entre deux nombres aléatoires identiques. En général, dans ce genre de cas, on réessaie de tirer des nombres aléatoires jusqu'à en trouver deux différents. Ici la collsion est possible, auquel cas l'ordre est fixé par le SGBD, pas l'algorithme.
*/
