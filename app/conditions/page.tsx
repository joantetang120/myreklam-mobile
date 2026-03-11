import Link from "next/link"
import { Separator } from "@/components/ui/separator"

export const metadata = {
  title: "Conditions Générales — MyReklam",
  description: "Conditions générales d'utilisation et mentions légales — MyReklam",
}

export default function ConditionsPage() {
  return (
    <main className="max-w-4xl mx-auto px-6 py-20">
      
      {/* HEADER */}
      <header className="text-center mb-14">
        <h1 className="text-4xl md:text-5xl font-extrabold tracking-tight text-gray-900 mb-4">
          Conditions Générales MyReklam
        </h1>
        <p className="text-lg text-gray-500">
          Dernière mise à jour : {new Date().toLocaleDateString('fr-FR', { year: 'numeric', month: 'long', day: 'numeric' })}
        </p>
      </header>

      {/* CONTENT */}
      <div className="space-y-12 text-gray-700 leading-relaxed">
        
        {/* MENTIONS LEGALES */}
        <section>
          <h2 className="text-3xl font-bold mb-6 text-gray-900">MENTIONS LEGALES</h2>
          <Separator className="mb-6" />
          <div className="space-y-4">
            <p>
              MYREKLAM est un site édité par la société MYREKLAM SAS au capital de 5.000 €, inscrite au Registre du Commerce et des Sociétés de NANCY n° RCS 810 545 491 ;
            </p>
            <p>
              MYREKLAM a son siège social au 59 Rue des Platanes, 54300 REHAINVILLER ;
            </p>
            <p>
              E-mail de contact :{" "}
              <a href="mailto:contact@myreklam.fr" className="text-primary underline hover:text-primary/80">
                contact@myreklam.fr
              </a>
            </p>
            <p>
              Le site internet MY REKLAM est hébergé par OVH.
            </p>
          </div>
        </section>

        {/* CONDITIONS GENERALES */}
        <section>
          <h2 className="text-3xl font-bold mb-6 text-gray-900">CONDITIONS GENERALES</h2>
          <Separator className="mb-6" />
          <div className="space-y-4 mb-6">
            <p>
              L'utilisation du site myreklam.fr est soumise à l'acceptation des présentes Conditions Générales. En accédant à MYREKLAM, vous vous engagez à vous référer régulièrement à la dernière version des Conditions Générales disponible en permanence sur le site. En cas de non-respect de ces conditions ou de mauvais comportement à l'égard d'un membre, MYREKLAM se réserve le droit d'interdire ou de restreindre l'accès au site.
            </p>
          </div>

          {/* Article 1 */}
          <div className="mt-8">
            <h3 className="text-2xl font-semibold mb-4 text-gray-900">1- Présentation de Myreklam.fr</h3>
            <Separator className="mb-4" />
            <div className="space-y-4">
              <p>
                MYREKLAM est une société française de mise en relation entre professionnels et particuliers.
              </p>
              <p>
                Fondée en 2015, la société Myreklam est une plateforme de partage de Bons plans, de publicité, d'informations et d'évènements dans le but d'aider les utilisateurs à trouver tout ce dont ils ont besoins. En 2021, Myreklam continue de s'agrandir à l'échelle nationale en développant un site web d'annonces gratuites et devient facilement accessible à tous, où que vous soyez.
              </p>
              <p>
                Le partage et la communication d'offre d'emploi et de formation ont permis à des entreprises de trouver la perle rare pour leur entreprise et aux particuliers de trouver un emploi ou une formation.
              </p>
              <p>
                L'objectif de cette plateforme est simple : <strong>Diffuser, Partager, Communiquer.</strong>
              </p>
              <p>
                Les utilisateurs professionnels du site myreklam.fr peuvent diffuser des annonces proposant des offres d'emplois et des formations. Ils peuvent communiquer sur leurs activités, partager des évènements mais également passer en relation avec des particuliers pour répondre à leurs besoins. Les professionnels peuvent aussi consulter directement les appels d'offres de tout type de marché sur cette plateforme et y répondre directement sur le site de l'annonceur.
              </p>
              <p>
                Les utilisateurs particuliers du site myreklam.fr peuvent diffuser des annonces de tout type de demandes : recherche d'emploi ou de formation, recherche de professionnels pour tous besoins etc.). Ils peuvent également partager des Bons plans avec la communauté MYREKLAM et consulter toutes les annonces diffusées par les professionnels et se mettre en relation via la messagerie instantanée, par mail ou par téléphone.
              </p>
            </div>
          </div>

          {/* Article 2 */}
          <div className="mt-8">
            <h3 className="text-2xl font-semibold mb-4 text-gray-900">2- Champ d'application</h3>
            <Separator className="mb-4" />
            <div className="space-y-4">
              <p>
                MYREKLAM propose les services et contenus numériques suivants (« les Services et Contenus Numériques ») :
              </p>
              <ul className="list-disc list-inside space-y-2 ml-4">
                <li>Possibilité de mettre un article dans la rubrique « Actualités »</li>
                <li>Partage de « bons plans » à la communauté d'utilisateurs du site MYREKLAM</li>
                <li>Partage d'offres d'emploi par les recruteurs pour trouver le candidat idéal</li>
                <li>Partage d'offres de formation</li>
                <li>Mise en ligne d'« évènements » à venir</li>
                <li>Publication des appels d'offre</li>
                <li>Possibilité de faire une demande ne rentrant dans aucune autre catégorie dans la rubrique « demandes » comme une demande d'emploi, recherche de logement ou proposition de services.</li>
              </ul>
              <p>
                Les présentes Conditions Générales s'appliquent, sans restriction ni réserve et à l'exclusion de toutes autres conditions, à toute vente de Services et Contenus Numériques fournis par le Vendeur effectuée au profit des consommateurs, clients professionnels et clients non professionnels.
                Elles précisent, notamment, les conditions d'utilisation du site de MYREKLAM, de passation de commande, de paiement et de fourniture des Services et Contenus Numériques commandés par les Clients.
              </p>
              <p>
                Le Client, qui reconnaît que les présentes Conditions Générales et leurs annexes, comportant les informations requises par la loi, lui ont été communiquées de manière claire et compréhensible, sur un support durable ou dans un document facilement téléchargeable, est tenu d'en prendre connaissance avant toute passation de commande.
              </p>
              <p>
                Le choix et l'achat d'un Service ou Contenu Numérique sont de la seule responsabilité du Client.
              </p>
              <p>
                Ces Conditions Générales sont systématiquement communiquées à tout Client préalablement à la conclusion du contrat de fourniture de Services et Contenus Numériques et prévaudront, le cas échéant, sur toute autre version ou tout autre document contradictoire.
              </p>
              <p>
                Le Client déclare avoir pris connaissance des présentes Conditions Générales et les avoir acceptées avant la conclusion du contrat de fourniture de Services et Contenus Numériques.
              </p>
              <p>
                La validation de la commande de Services et Contenus Numériques par le Client vaut acceptation sans restriction ni réserve des présentes Conditions Générales.
              </p>
              <p>
                Ces Conditions Générales pouvant faire l'objet de modifications ultérieures, la version applicable au Client est celle en vigueur au jour de l'inscription à la Plateforme de mise en relation.
              </p>
            </div>
          </div>

          {/* Article 3 */}
          <div className="mt-8">
            <h3 className="text-2xl font-semibold mb-4 text-gray-900">3- Responsabilité</h3>
            <Separator className="mb-4" />
            <div className="space-y-4">
              <p>
                MYREKLAM, étant simplement une plateforme de mise en relation, ne garantit pas la fiabilité ni la véracité des offres d'emploi, des bons plans, ni des évènements et ne peut en aucun cas être inquiétée dans sa responsabilité concernant un conflit entre les différents utilisateurs de la Plateforme. Ainsi l'utilisateur est averti que MYREKLAM n'examine pas le contenu avant sa diffusion et, en conséquence, ne garantit pas l'opportunité, la probité ou la qualité de ce contenu. MYREKLAM se réserve le droit, à sa seule discrétion, de refuser ou de déplacer tout contenu disponible sur le site internet myreklam.fr.
              </p>
            </div>
          </div>

          {/* Article 4 */}
          <div className="mt-8">
            <h3 className="text-2xl font-semibold mb-4 text-gray-900">4- Conditions financières - Tarifs</h3>
            <Separator className="mb-4" />
            <div className="space-y-4">
              <p>
                L'inscription sur le site myreklam.fr est gratuite pour les particuliers et les professionnels. Cependant cet accès est limité à la navigation sur le site en fonction du profil utilisateur.
              </p>
              <p>
                Le particulier peut consulter toutes les catégories, et déposer gratuitement des annonces dans les catégories « DEMANDES », « EVENEMENTS », « BONS PLANS » il peut répondre ou postuler aux offres d'emploi, offres de formation. Un utilisateur particulier ne pourra en revanche pas répondre aux appels d'offres, ni publier des annonces d'offres d'emploi ou de formations sur le site myreklam.fr mais seulement les consulter et postuler.
              </p>
              <p>
                Le professionnel quant à lui, peut également s'inscrire gratuitement sur le site myreklam.fr mais aura un accès limité sur la plateforme. Il peut consulter l'ensemble des annonces publiées dans les différentes catégories mais ne peut pas déposer d'annonces ou communiquer avec les autres utilisateurs. Pour ce faire le professionnel doit souscrire un abonnement :
              </p>
              <p>
                Le professionnel ayant souscrit un abonnement pourra utiliser la plateforme MYREKLAM pour y mettre des articles, des annonces ou tout autre contenu prévu à l'ARTICLE 2 qu'après la confirmation de l'acceptation de son inscription par MYREKLAM et surtout après encaissement par MYREKLAM de l'intégralité du prix.
              </p>
              <p>
                Les services proposés par MYREKLAM sont fournis sur la base d'un abonnement qui peut être mensuel ou annuel en fonction du souhait du client.
              </p>
              <div className="bg-gray-50 dark:bg-gray-800 p-4 rounded-lg my-4">
                <ul className="space-y-2">
                  <li><strong>L'abonnement mensuel est au prix de 6,90 €.</strong></li>
                  <li><strong>L'abonnement annuel est au prix de 59,90 €.</strong></li>
                </ul>
              </div>
              <p>
                L'abonnement permet aux professionnels d'avoir un accès premium et illimité sur le site myreklam.fr. Il n'y aura en effet aucune limite sur le nombre d'annonces à déposer, ni sur le nombre de photo à intégrer dans l'annonce déposé et il peut également rentrer en relation avec tous les utilisateurs de la plateforme et avoir une utilisation complète du site myreklam.fr
              </p>
              <p>
                Les tarifs sont exprimés en euros.
              </p>
              <p>
                Les modalités tarifaires pourront changer en cours d'année pour les nouvelles inscriptions mais resteront inchangées pour les clients ayant accepté et payé le prix pour l'année en cours.
              </p>
              <p>
                En tout état de cause, le prix à payer sera celui en vigueur dans les conditions générales au moment de l'inscription.
              </p>
              <p>
                Le paiement se fait en suivant les étapes strictement nécessaires à l'inscription sur le site internet myreklam.fr.
              </p>

              <div className="mt-6">
                <h4 className="text-xl font-semibold mb-3 text-gray-900">Résiliation</h4>
                <div className="space-y-3">
                  <p>
                    Le client ayant souscrit à l'abonnement mensuel aura la possibilité de le résilier à tout moment.
                  </p>
                  <p>
                    Dans le cadre de cet abonnement mensuel, la résiliation prendra effet à la fin du mois de la résiliation, à l'échéance, et l'abonnement sera dû pour ledit mois.
                  </p>
                  <p>
                    Pour la résiliation, il suffit d'aller dans le compte utilisateur et cliquer sur <strong>GERER MON ABONNEMENT</strong> et se désabonner.
                  </p>
                  <p>
                    Dans le cadre de l'abonnement annuel, le client ne pourra mettre fin à son contrat qu'une fois le terme atteint. Il s'agit là d'un abonnement d'un an et le souhait de résiliation du client s'apparente en réalité à son refus de renouveler tacitement le contrat.
                  </p>
                  <p>
                    Les abonnements, mensuel ou annuel, font l'objet d'une reconduction tacite à l'échéance contractuelle.
                  </p>
                  <p>
                    Dans le cas où le renouvellement échoue en raison des changements de coordonnées bancaires non mis à jour, myreklam.fr se donne le droit de poursuivre l'exécution du contrat conformément aux règles de droit commun.
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Article 5 */}
          <div className="mt-8">
            <h3 className="text-2xl font-semibold mb-4 text-gray-900">5- Propriété intellectuelle</h3>
            <Separator className="mb-4" />
            <div className="space-y-4">
              <p>
                Les Services et Contenus Numériques délivrés au Client sont destinés à un usage strictement privé. Toute reproduction, représentation ou usage public collectif sont prohibés.
              </p>
              <p>
                De même, tout échange, revente ou louage à un tiers Services et Contenus Numériques délivrées est strictement interdit et sera considéré comme une violation du droit d'auteur passible de poursuites pénales.
              </p>
              <p>
                Les Services et Contenus Numériques ainsi que tous les éléments reproduits sur la fiche produit de chaque Service et Contenu Numérique (notamment textes, commentaires, illustrations, logos et documents iconographiques) sont protégés par le Code de la Propriété Intellectuelle et par les normes internationales applicables.
              </p>
              <p>
                L'achat et l'utilisation des Services et Contenus Numériques par le Client ne saurait conférer à celui-ci comme à quiconque, sur les éléments protégés susvisés, un droit autre que celui d'un usage strictement personnel, non collectif et non marchand.
              </p>
              <p>
                Le client ne bénéficie donc que d'un droit d'utilisation personnel des Services et Contenus Numériques délivrés, dans un cadre strictement privé et gratuit. Toute utilisation hors du cadre des présentes est strictement prohibée et toute utilisation à des fins autres que privées expose le client à des poursuites judiciaires civiles et /ou pénales.
              </p>
            </div>
          </div>

          {/* Article 6 */}
          <div className="mt-8">
            <h3 className="text-2xl font-semibold mb-4 text-gray-900">6- Médiation</h3>
            <Separator className="mb-4" />
            <div className="space-y-4">
              <div>
                <h4 className="text-xl font-semibold mb-2 text-gray-900">Pour les consommateurs :</h4>
                <p>
                  Conformément aux articles du code de la consommation L.611-1 et suivant, il est prévu que pour tout litige de nature contractuelle n'ayant pu être résolu dans le cadre d'une réclamation préalablement introduite auprès de notre service clients, vous pouvez, en votre qualité de consommateur, recourir gratuitement à la médiation en contactant l'Association Nationale des Médiateurs (ANM) soit par courrier en écrivant au 62, rue Tiquetonne 75002 PARIS soit par e-mail en remplissant le formulaire de saisine en ligne à l'adresse suivante:{" "}
                  <a href="https://www.anm-conso.com" target="_blank" rel="noopener noreferrer" className="text-primary underline hover:text-primary/80">
                    www.anm-conso.com
                  </a>.
                </p>
              </div>
              <div>
                <h4 className="text-xl font-semibold mb-2 text-gray-900">Pour les professionnels :</h4>
                <p>
                  Conformément à l'article 1530 du Code de procédure civile, en cas de difficultés soulevées par l'exécution, l'interprétation, ou la cessation de leur contrat, les Parties s'engagent préalablement à toutes actions contentieuses, à soumettre leur litige à un centre de médiation compétent selon les dispositions prévues par le règlement de ce centre. Conformément aux dispositions de l'article 122 du Code de procédure civile, durant la procédure de médiation, les Parties s'interdisent d'exercer une action en justice à l'encontre de l'autre, à défaut elles s'exposeront à une fin de non-recevoir.
                </p>
              </div>
            </div>
          </div>

          {/* Article 7 */}
          <div className="mt-8">
            <h3 className="text-2xl font-semibold mb-4 text-gray-900">7- Loi applicable</h3>
            <Separator className="mb-4" />
            <div className="space-y-4">
              <p>
                Les conditions d'utilisation du site et les services proposés sont soumis au droit français.
              </p>
              <p>
                Tout litige relatif à l'interprétation ou l'exécution des présentes conditions d'utilisation ou à l'exécution des Services proposés sera soumis au Tribunal compétent de Strasbourg, France.
              </p>
            </div>
          </div>

          {/* Article 8 */}
          <div className="mt-8">
            <h3 className="text-2xl font-semibold mb-4 text-gray-900">8- Acceptation du client</h3>
            <Separator className="mb-4" />
            <div className="space-y-4">
              <p>
                Les présentes Conditions Générales sont expressément agréés et acceptées par le Client, qui déclare et reconnaît en avoir une parfaite connaissance, et renonce, de ce fait, à se prévaloir de tout document contradictoire et, notamment, ses propres conditions générales, qui seront inopposables à MYREKLAM , même s'il en a eu connaissance.
              </p>
            </div>
          </div>
        </section>

        {/* POLITIQUE DE CONFIDENTIALITE */}
        <section>
          <h2 className="text-3xl font-bold mb-6 text-gray-900">POLITIQUE DE CONFIDENTIALITE</h2>
          <Separator className="mb-6" />
          <div className="space-y-4">
            <div>
              <h3 className="text-xl font-semibold mb-3 text-gray-900">PREAMBULE</h3>
              <p>
                Dans le respect du règlement européen sur la protection des données personnelles (RGPD), les conditions générales d'utilisation des services d'intermédiation en ligne doivent décrire les conditions d'accès des vendeurs aux données personnelles communiquées par les consommateurs (art. 9).
              </p>
              <p className="mt-4">
                MYREKLAM, rédacteur des présentes, met en oeuvre des traitements de données à caractère personnel qui ont pour base juridique :
              </p>
              <ul className="list-disc list-inside space-y-2 ml-4 mt-4">
                <li>
                  <strong>Soit l'intérêt poursuivi par MYREKLAM</strong> lorsqu' elle poursuit les finalités suivantes :
                  <ul className="list-circle list-inside ml-6 mt-2 space-y-1">
                    <li>la prospection ;</li>
                    <li>la gestion de la relation avec ses clients et prospects ;</li>
                    <li>l'organisation, l'inscription et l'invitation à des événements de la Société ;</li>
                    <li>le traitement, l'exécution, la prospection, la production, la gestion, le suivi des demandes et des dossiers des clients ;</li>
                    <li>la rédaction d'actes pour le compte de ses clients.</li>
                  </ul>
                </li>
                <li>
                  <strong>Soit le respect d'obligations légales et réglementaires</strong> lorsqu'il met en oeuvre un traitement ayant pour finalité :
                  <ul className="list-circle list-inside ml-6 mt-2 space-y-1">
                    <li>la prévention du blanchiment et du financement du terrorisme et la lutte contre la corruption ;</li>
                    <li>la facturation ;</li>
                    <li>la comptabilité</li>
                  </ul>
                </li>
              </ul>
              <p className="mt-4">
                MYREKLAM ne conserve les données que pour la durée nécessaire aux opérations pour lesquelles elles ont été collectées ainsi que dans le respect de la réglementation en vigueur.
              </p>
              <p>
                A cet égard, les données des clients sont conservées pendant la durée des relations contractuelles augmentée de 3 ans à des fins d'animation et prospection, sans préjudice des obligations de conservation ou des délais de prescription. En matière de prévention du blanchiment et du financement du terrorisme, les données sont conservées 5 ans après la fin des relations avec la Société. En matière de comptabilité, elles sont conservées 10 ans à compter de la clôture de l'exercice comptable.
              </p>
              <p>
                Les données des prospects sont conservées pendant une durée de 3 ans si aucune participation ou inscription aux événements de la Société n'a eu lieu.
              </p>
              <p>
                Les données traitées sont destinées aux personnes habilitées de la Société, ainsi qu'à ses prestataires.
              </p>
              <p>
                Dans les conditions définies par la loi Informatique et libertés et le règlement européen sur la protection des données, les personnes physiques disposent d'un droit d'accès aux données les concernant, de rectification, d'interrogation, de limitation, de portabilité et d'effacement.
              </p>
              <p>
                Les personnes concernées par les traitements mis en œuvre disposent également du droit de s'opposer à tout moment, pour des raisons tenant à leur situation particulière, à un traitement des données à caractère personnel ayant comme base juridique l'intérêt légitime de la Société, ainsi qu'un droit d'opposition à la prospection commerciale.
              </p>
              <p>
                Elles disposent également du droit de définir des directives générales et particulières définissant la manière dont elles entendent que soient exercées, après leur décès, les droits mentionnés ci-dessus accompagné d'une copie d'une pièce d'identité signée.
              </p>
              <p>
                Les personnes concernées disposent du droit d'introduire une réclamation auprès de la CNIL.
              </p>
            </div>
          </div>
        </section>

        {/* GESTION DES COOKIES */}
        <section>
          <h2 className="text-3xl font-bold mb-6 text-gray-900">GESTION DES COOKIES</h2>
          <Separator className="mb-6" />
          <div className="space-y-4">
            <p>
              Lorsque vous visitez le site MYREKLAM, un "cookie" peut s'installer automatiquement sur votre ordinateur. Un Cookie est un petit fichier texte déposé sur le disque dur de votre terminal lors de votre visite sur un site internet. Il enregistre certaines informations relatives à votre navigation ou sur votre comportement en ligne qui nous permettent d'améliorer et de faciliter votre expérience en qualité d'internaute.
            </p>
            <p>
              Ce procédé est donc destiné à connaître les parties du site qui vous intéressent, afin de pouvoir mieux répondre à vos attentes et vos besoins.
            </p>
            <p>
              Ces "cookies" vous éviteront également de fournir à chaque nouvelle navigation sur notre site des informations que vous nous avez communiquées dans la mesure où ils conserveront les informations fournies à une date antérieure. Nous vous rappelons que vous pouvez vous opposer à l'enregistrement de "cookies" en désactivant cette fonction dans les paramètres de votre navigateur.
            </p>
            <p>
              MYREKLAM privilégie la transparence dans le traitement de vos données. A ce titre et pour que votre information soit la plus claire possible, vous trouverez ci-dessous les différents cookies utilisés sur le Site myreklam.fr et leur finalité :
            </p>
            <ul className="list-disc list-inside space-y-3 ml-4 mt-4">
              <li>
                <strong>Les cookies indispensables à la navigation :</strong> ces cookies sont indispensables pour vous permettre de parcourir nos sites internet et en utiliser au mieux les diverses functionnalités.
              </li>
              <li>
                <strong>Les cookies de mesure d'audience :</strong> ces cookies recueillent de manière anonyme des informations lors de vos visites sur notre site. Leur objectif est de permettre l'analyse des comportements de navigation sur le site à des fins d'optimisation.
              </li>
              <li>
                <strong>Les cookies de fonctionnalité :</strong> ces cookies permettent à nos sites web de mémoriser les choix que vous avez fait lors de votre visite. Ils servent à améliorer l'expérience de navigation en apportant des fonctionnalités enrichies, telles que la lecture vidéo, l'affichage de contenus récemment consultés et l'enregistrement des préférences (paramètres de langue et de localisation, par exemple).
              </li>
              <li>
                <strong>Les cookies d'authentification :</strong> ces cookies agissent par exemple de manière à vérifier que votre mot de passe fonctionne et que vous restez connecté quand vous changez de page sur le site, et ils aident le site à se souvenir de détails tels que le contenu de votre panier ou l'étape que vous avez atteinte lors d'une commande. Ils veillent également sur votre sécurité lorsque vous êtes connecté et aident à assurer la cohérence du site pendant votre visite.
              </li>
              <li>
                <strong>Les cookies de session :</strong> Les cookies de session permettent à notre site web de reconnaitre ses utilisateurs afin que tous les changements ou toutes les sélections d'articles ou de données qu'ils effectuent sur une page soient gardés en mémoire d'une page à une autre. Par exemple, ils vont permettre de conserver les données saisies lors d'un devis en ligne sur plusieurs écrans (token). Ces cookies expirent lors de la fermeture de votre navigateur.
              </li>
            </ul>

            <div className="mt-6">
              <h3 className="text-xl font-semibold mb-3 text-gray-900">Vos choix concernant les cookies :</h3>
              <p>
                Sur vos ordinateurs, Smartphones et autres terminaux d'accès à Internet, par défaut le logiciel de navigation accepte les Cookies présents sur le site. Mais vous pouvez vous opposer à l'enregistrement des cookies en configurant les préférences de votre logiciel de navigation.
              </p>
              <p className="mt-4">
                Pour ce faire, il vous suffit de vous reporter à vos logiciels et de suivre les instructions suivantes :
              </p>
              
              <div className="space-y-4 mt-6">
                <div>
                  <h4 className="font-semibold mb-2 text-gray-900">Sous Microsoft Internet Explorer</h4>
                  <ul className="list-disc list-inside space-y-1 ml-4">
                    <li>Choisissez le menu "Outils », puis "Options Internet"</li>
                    <li>Cliquez sur l'onglet "Confidentialité"</li>
                    <li>Sélectionnez le niveau souhaité à l'aide du curseur</li>
                  </ul>
                </div>
                
                <div>
                  <h4 className="font-semibold mb-2 text-gray-900">Sous Mozilla Firefox</h4>
                  <ul className="list-disc list-inside space-y-1 ml-4">
                    <li>Choisissez le menu « Outils » puis « Options »</li>
                    <li>Cliquez sur l'onglet « Vie privée »</li>
                    <li>Dans la liste déroulante « Règles de conservation » sélectionnez le niveau souhaité</li>
                  </ul>
                </div>
                
                <div>
                  <h4 className="font-semibold mb-2 text-gray-900">Sous Google Chrome</h4>
                  <ul className="list-disc list-inside space-y-1 ml-4">
                    <li>Cliquez sur l'icône permettant d'afficher le menu des paramètres</li>
                    <li>Cliquez sur « Options »</li>
                    <li>Dans la zone "Historique", sélectionnez "utiliser les paramètres personnalisés pour l'historique"</li>
                    <li>Choisissez le niveau souhaité</li>
                  </ul>
                </div>
                
                <div>
                  <h4 className="font-semibold mb-2 text-gray-900">Sous Safari</h4>
                  <ul className="list-disc list-inside space-y-1 ml-4">
                    <li>Cliquez dans le menu « Safari »</li>
                    <li>Cliquez sur « Préférences »</li>
                    <li>Dans l'onglet « Sécurité » sélectionnez le niveau souhaité.</li>
                  </ul>
                </div>
              </div>
              
              <p className="mt-6">
                Nous attirons votre attention sur le fait que le refus des cookies peut vous empêcher d'accéder à certaines fonctionnalités du site ou en altérer l'efficacité.
              </p>
            </div>
          </div>
        </section>

        {/* LOTERIES PUBLICITAIRES */}
        <section>
          <h2 className="text-3xl font-bold mb-6 text-gray-900">LOTERIES PUBLICITAIRES</h2>
          <Separator className="mb-6" />
          <div className="space-y-4">
            <p>
              Les loteries à l'égard des consommateurs sont licites, sauf si elles constituent des pratiques commerciales déloyales au sens de l'article L 121-1 du Code de la consommation (C. consom. art. L 121-20).
            </p>
            <p>
              Les loteries commerciales sont définies comme les « pratiques commerciales mises en œuvre par les professionnels à l'égard des consommateurs, sous la forme d'opérations promotionnelles tendant à l'attribution d'un gain ou d'un avantage de toute nature par la voie d'un tirage au sort, quelles qu'en soient les modalités, ou par l'intervention d'un élément aléatoire » (C. consom. art. L 121-20).
            </p>
            <p>
              Toutes les loteries commerciales à destination des consommateurs sont visées. Peu importe les modalités du tirage au sort, avec prétirage - la révélation du résultat étant immédiate pour le participant - ou non. Peu importe également les modalités de la participation du joueur, financière (obligation d'achat, utilisation d'un timbre postal, numéro de téléphone surtaxé, etc.) ou non.
            </p>
            <p>
              MYREKLAM est susceptible d'organiser des jeux concours respectant les dispositions du droit de la consommation ou des loteries commerciales au sens des articles du Code de la sécurité intérieure.
            </p>
            <p>
              Une loterie à destination des consommateurs n'est interdite que si elle constitue une pratique commerciale déloyale au sens de l'article L 121-1 du Code de la consommation, c'est-à-dire si elle est contraire à la diligence professionnelle et altère ou est susceptible d'altérer de manière substantielle, le comportement économique du consommateur normalement informé et raisonnablement attentif et avisé.
            </p>
            <p>
              Entrent principalement dans le champ de l'interdiction des loteries déloyales les loteries qui constituent une pratique commerciale trompeuse (C. consom. art. L 121-2 s.) ou une pratique commerciale agressive (art. L 121-6 s.), de telles pratiques étant par définition déloyales au sens de l'article L 121-1.
            </p>
            <p>
              Les documents publicitaires présentant l'opération doivent donc mentionner les informations minimales pouvant permettre aux consommateurs d'appréhender le mécanisme de l'opération, leurs chances de gain et surtout ce pour quoi ils jouent.
            </p>
            <p>
              MYREKLAM s'engage, dans toutes les loteries proposées, à décrire la dotation mise en jeu si l'accroche incitant les consommateurs à participer mentionne la nature des lots.
            </p>
            <p>
              Si les lots sont fabriqués spécialement pour l'opération, leur valeur commerciale sera appréciée en fonction du prix payé par l'organisateur au fabricant, augmenté de la « marge bénéficiaire habituelle du secteur commercial considéré » (Rép. Stasi : AN 21-5-1990 p. 2382).
            </p>
            <p>
              MYREKLAM, en tant qu'organisateur de loteries, ne peut valablement proposer pour lots des produits portant une marque sans l'autorisation du propriétaire de celle-ci. En effet, le propriétaire d'une marque est en droit de s'opposer à ce que les produits la portant puissent être diffusés dans le public dès lors que cette diffusion n'a pas pour objet leur commercialisation (Cass. com. 2-7-1996 : RJDA 12/96 n° 1558). En outre, il est rappelé que lorsqu'il s'agit d'une marque réputée, la diffusion d'une telle publicité constitue un acte de parasitisme car elle vise à tirer profit de la renommée des produits offerts en lots pour permettre à l'annonceur, qui ne les vend pas, de se dispenser d'un effort pour la promotion de ses propres produits (CA Versailles 19-11-1998 : RJDA 6/99 n° 740).
            </p>
            <p>
              MYREKLAM est conscient et rappelle aux utilisateurs et clients qu'il est interdit de demander au joueur une participation financière en contrepartie de l'obtention de son gain, et ce, même si la participation financière est minime (par exemple, timbre-poste, SMS ou appel surtaxé) ; en effet, une telle pratique est réputée agressive (C. consom. art. L 121-7, 7°).
            </p>
            <p>
              MYREKLAM pourra informer les utilisateurs de la plateforme de l'existence des loteries par la diffusion d'articles sur le site internet ainsi que sur tous les réseaux sociaux lui appartenant.
            </p>
          </div>
        </section>

      </div>

      {/* FOOTER */}
      <footer className="mt-20 text-center text-gray-500">
        Besoin d'aide supplémentaire ?{" "}
        <Link href="/contact" className="text-primary underline font-medium hover:text-primary/80">
          Contactez-nous
        </Link>.
      </footer>
    </main>
  )
}
