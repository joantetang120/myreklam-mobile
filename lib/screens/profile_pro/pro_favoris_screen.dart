import 'package:flutter/material.dart';
import 'package:myreklam/widgets/categories_icon.dart';

class ProFavorisScreen extends StatefulWidget {
  const ProFavorisScreen({super.key});

  @override
  State<ProFavorisScreen> createState() => _ProFavorisScreenState();
}

class _ProFavorisScreenState extends State<ProFavorisScreen> {
  String selectedCategory = 'Bons plans';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2E9B5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mes Favoris',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Faire une recherche',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filtre par catégorie',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF8A40),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.sort, size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Plus récents',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    CategoriesIcon(
                      title: "Bons plans",
                      iconColor: const Color.fromARGB(255, 252, 116, 37),
                      bgColor: Color(0xFFFFE0B2).withOpacity(0.2),
                      icon: Icons.card_giftcard_outlined,
                      onTap: () {},
                    ),
                    const SizedBox(width: 15),
                    CategoriesIcon(
                      title: "Offre d'emploi",
                      iconColor: Colors.lightBlueAccent,
                      bgColor: Color(0xFFB3E5FC).withOpacity(0.2),
                      iconAsset: 'assets/images/offres.png',
                      onTap: () {},
                    ),
                    const SizedBox(width: 15),
                    CategoriesIcon(
                      title: "Formations",
                      iconColor: Colors.purple,
                      bgColor: Color(0xFFE1BEE7).withOpacity(0.1),
                      iconAsset: 'assets/images/Formation.png',
                      onTap: () {},
                    ),
                    const SizedBox(width: 15),
                    CategoriesIcon(
                      title: "Evenements",
                      iconColor: Colors.green,
                      bgColor: Color(0xFFE6F7EF).withOpacity(0.5),
                      icon: Icons.event_outlined,
                      onTap: () {},
                    ),
                    const SizedBox(width: 15),
                    CategoriesIcon(
                      title: "Demandes",
                      iconColor: const Color.fromARGB(255, 252, 231, 49),
                      bgColor: Color.fromARGB(255, 255, 250, 178).withOpacity(0.2),
                      icon: Icons.chat_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildFavorisCard(
              userName: 'Jane Cooper',
              userType: 'Particulier',
              description:
                  'Promo Appareil photo Hybride Sony A6400 Noir + Objectif E PZ 16-50 mm',
              imagePath: 'assets/images/profil_pro/post-1.png',
              price: '12.90€',
              oldPrice: '25.90€',
              discount: '-50%',
              category: 'High-Tech . Matériel',
              availability: 'En ligne disponible chez Amazon',
              time: 'il y a 1 semaine',
              likes: 675,
              comments: 2,
            ),
            _buildFavorisCard(
              userName: 'Jane Cooper',
              userType: 'Particulier',
              description:
                  'Promo Appareil photo Hybride Sony A6400 Noir + Objectif E PZ 16-50 mm',
              imagePath: 'assets/images/profil_pro/post-1.png',
              price: '12.90€',
              oldPrice: '25.90€',
              discount: '-50%',
              category: 'High-Tech . Matériel',
              availability: 'En ligne disponible chez Amazon',
              time: 'il y a 1 semaine',
              likes: 675,
              comments: 2,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }


  Widget _buildFavorisCard({
    required String userName,
    required String userType,
    required String description,
    required String imagePath,
    required String price,
    String? oldPrice,
    String? discount,
    required String category,
    required String availability,
    required String time,
    required int likes,
    required int comments,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: AssetImage(
                  'assets/images/dashboard_particulier/Ellipse 10.png',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      child: Text(
                        userType,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.favorite, color: Colors.grey[400], size: 22),
              const SizedBox(width: 6),
              Icon(Icons.more_horiz, color: Colors.grey[400], size: 22),
              const SizedBox(width: 6),
              Icon(Icons.close, color: Colors.grey, size: 22),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              children: [
                TextSpan(text: description),
                const TextSpan(
                  text: '...plus',
                  style: TextStyle(color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              if (discount != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF8A40),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      discount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    children: [
                      const TextSpan(text: 'En ligne disponible chez '),
                      TextSpan(
                        text: 'Amazon',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 14,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 10),
              ),
              Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                time,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF8A40),
                ),
              ),
              if (oldPrice != null) ...[
                const SizedBox(width: 10),
                Text(
                  oldPrice,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[400],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF8A40),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: Image.asset(
                  'assets/images/profil_pro/paper.png',
                  width: 16,
                  height: 16,
                ),
                label: const Text(
                  'Voir le bon plan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up_outlined, size: 18, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '$likes',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Image.asset(
                'assets/images/profil_pro/ann-card-comm.png',
                width: 19,
                height: 19,
                color: Colors.grey[500],
              ),
              const SizedBox(width: 4),
              Text(
                '$comments',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(width: 16),
              Image.asset(
                'assets/images/profil_pro/ann-card-share.png',
                width: 19,
                height: 19,
                color: Colors.grey[500],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
