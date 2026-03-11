<?php

// Bloquer l'accès direct depuis un navigateur en renvoyant une erreur 404
if ($_SERVER['REQUEST_METHOD'] === 'GET' && basename(__FILE__) == basename($_SERVER['PHP_SELF'])) {
    http_response_code(404);
    exit;
}
// Inclure la connexion à la base de données
include_once(__DIR__ . "/db.php");
include_once(__DIR__ . "/packages/NotificationBrevoAndWeb.php");

// Autoriser les requêtes depuis n'importe quel domaine
header("Access-Control-Allow-Origin: *");
// La requête est une pré-vérification CORS, donc retourner les en-têtes appropriés sans exécuter le reste du script
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Si la méthode n'est pas POST, retourner un message simple et quitter
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(404);
    exit;
}



// Récupérer les données du formulaire
$method = $_POST['Method']; // "create", "read", "update" ou "delete"
$id = $_POST['Id']; // ID de l'enregistrement à modifier ou supprimer
$data = $_POST['Data']; // Données à insérer ou mettre à jour $newPassword
$page = $_POST['Page'];
$category = $_POST['Category'];
$searchbar = strtolower($_POST['Searchbar']); // Mettre le terme de recherche en minuscule token  getTableColumns
$email = $_POST["userEmail"];
$password = $_POST["userPassword"];
$token = $_POST["token"];
$newPassword = $_POST["newPassword"];
$tableName = $_POST["tableName"];


if (
    $method !== 'create' && $method !== 'readAll' && $method !== 'read' && $method !== 'resetPassword' && $method !== 'updatePassword'
    && $method !== 'update'  && $method !== 'delete'  && $method !== 'paginate'  && $method !== 'verify'   && $method !== 'readAllByUserId'
    && $method !== 'paginateSize'  && $method !== 'searchbar'  && $method !== 'readByName' && $method !== 'getTableColumns'
    && $method !== 'deleteAccount' && $method !== 'deleteFile' && $method !== 'getUserIdFromToken'
) {
    http_response_code(404);
    exit;
}



// Fonction pour définir le type de contenu JSON
function setJsonHeader()
{
    header('Content-Type: application/json');
}

function logToFile($message)
{
    $logFile = __DIR__ . '/log.txt';
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$timestamp] $message" . PHP_EOL, FILE_APPEND);
}


function createRecord($conn, $email, $password)
{
    try {
        logToFile("createRecord called with email: $email");
        // Vérifier si l'utilisateur existe déjà
        $query = 'SELECT * FROM "users" WHERE "Email" = :email';
        $statement = $conn->prepare($query);
        $statement->bindParam(':email', $email);
        $statement->execute();
        $result = $statement->fetch(PDO::FETCH_ASSOC);

        setJsonHeader();
        if ($result) {
            logToFile("createRecord failed: User already exists");
            echo json_encode(array(
                "status" => "error",
                "message" => "Un utilisateur avec cette adresse mail existe déjà. S'il s'agit de vous, veuillez vous connecter."
            ));
        } else {
            // Hasher le mot de passe
            $hashed_password = password_hash($password, PASSWORD_DEFAULT);

            $id = generateGUID();
            $part1 = generateGUID();
            $part2 = generateGUID();
            $token = $part1 . '-' . $id . '-' . $part2;

            logToFile("Inserting new user with ID: $id and email: $email, token : $token");

            // Requête d'insertion
            $query0 = 'INSERT INTO "users" ("Id", "Email", "Password", "Token", "isVerified") 
                       VALUES (:id, :email, :password, :token, 0)';
            $statement0 = $conn->prepare($query0);
            $statement0->bindParam(':id', $id);
            $statement0->bindParam(':email', $email);
            $statement0->bindParam(':password', $hashed_password);
            $statement0->bindParam(':token', $token);
            $result0 = $statement0->execute();

            if ($result0) {
                // Récupérer l'utilisateur nouvellement créé
                $query01 = 'SELECT * FROM "users" WHERE "Email" = :email';
                $statement01 = $conn->prepare($query01);
                $statement01->bindParam(':email', $email);
                $statement01->execute();
                $result01 = $statement01->fetch(PDO::FETCH_ASSOC);

                if ($result01) {
                    $name = "Utilisateur";
                    $link = $_POST["Link"] ?? null;
                    if (!$link) {
                        // Si ton appel vient d'une requête JSON
                        $input = json_decode(file_get_contents('php://input'), true);
                        logToFile("Input data: " . print_r($input, true));
                        $link = $input['Link'] ?? $input['link'] ?? '';
                        logToFile("Link from input: $link");
                    }
                    $monLink = rtrim($link, '/') . '/verify?token=' . $token . '&email=' . urlencode($email);

                    $link = rtrim($link, '/') . '/verify?token=' . $token . '&email=' . urlencode($email);
                    logToFile("Verification link: $link");
                    logToFile("MonLink: $monLink");

                    // Validation de l'email
                    if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                        logToFile("Invalid or missing email: $email");
                        echo json_encode(array(
                            "status" => "error",
                            "message" => "Email invalide ou manquant",
                            "email" => $email
                        ));
                        return;
                    }

                    // Utiliser SendMail.php localement au lieu de cURL
                    require_once(__DIR__ . '/SendMail.php');
                    
                    // Appel correct de la fonction sendMail avec tous les paramètres
                    logToFile("Sending verification email to: " . $_POST['userEmail'] . " with link: " . $monLink);
                    $mailResult = sendMail($_POST['userEmail'], "", 22, ['username' => "", 'link' => $monLink], $monLink);
                    logToFile("sendMail result: " . print_r($mailResult, true));

                    if ($mailResult && $mailResult['status'] === 'success') {
                        echo json_encode(array(
                            "status" => "success",
                            "message" => "Utilisateur créé avec succès et email envoyé.",
                            "id" => $result01['Id'],
                            "token" => $token,
                            "email" => $result01['Email'],
                            "emailSent" => true
                        ));
                    } else {
                        echo json_encode(array(
                            "status" => "success",
                            "message" => "Utilisateur créé avec succès. Un email de vérification a été envoyé. Si vous ne le recevez pas, vérifiez vos spams.",
                            "id" => $result01['Id'],
                            "token" => $token,
                            "email" => $result01['Email'],
                            "emailSent" => false
                        ));
                    }
                }
            } else {
                echo json_encode(array(
                    "status" => "failure",
                    "message" => "Échec de la création de l'utilisateur",
                    "error" => $statement0->errorInfo()
                ));
            }
        }
    } catch (Exception $e) {
        setJsonHeader();
        echo json_encode(array(
            "status" => "error",
            "message" => "Erreur du serveur",
            "details" => $e->getMessage()
        ));
    }
}


function generateGUID()
{
    if (function_exists('com_create_guid')) {
        return trim(com_create_guid(), '{}');
    } else {
        return sprintf(
            '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0xffff)
        );
    }
}

function forgotPassword($conn, $email)
{
    try {
        $query = 'SELECT * FROM "users" WHERE "Email" = :email';
        $statement = $conn->prepare($query);
        $statement->bindParam(':email', $email);
        $statement->execute();
        $result = $statement->fetch(PDO::FETCH_ASSOC);

        setJsonHeader();

        logToFile("forgotPassword called with email: $email");

        // Récupérer le corps brut et logger.
        $rawInput = file_get_contents('php://input');
        if ($rawInput) {
            logToFile("forgotPassword raw input: " . $rawInput);

            // Essayer d'abord le JSON
            $jsonInput = json_decode($rawInput, true);
            if (is_array($jsonInput)) {
                foreach ($jsonInput as $k => $v) {
                    if (!isset($_POST[$k])) $_POST[$k] = $v;
                }
                logToFile("forgotPassword parsed json input: " . print_r($jsonInput, true));
            } else {
                parse_str($rawInput, $parsed);
                if (is_array($parsed) && count($parsed) > 0) {
                    foreach ($parsed as $k => $v) {
                        if (!isset($_POST[$k])) $_POST[$k] = $v;
                    }
                    logToFile("forgotPassword parsed form input: " . print_r($parsed, true));
                } else {
                    logToFile("forgotPassword: raw input could not be parsed as json or form data");
                }
            }
            
            if (empty($_POST['Link'])) {
                if (!empty($jsonInput['Link'] ?? null)) {
                    $_POST['Link'] = $jsonInput['Link'];
                    logToFile("forgotPassword Link set from json (Link): " . $_POST['Link']);
                } elseif (!empty($jsonInput['link'] ?? null)) {
                    $_POST['Link'] = $jsonInput['link'];
                    logToFile("forgotPassword Link set from json (link): " . $_POST['Link']);
                } elseif (!empty($parsed['Link'] ?? null)) {
                    $_POST['Link'] = $parsed['Link'];
                    logToFile("forgotPassword Link set from parsed form (Link): " . $_POST['Link']);
                } elseif (!empty($parsed['link'] ?? null)) {
                    $_POST['Link'] = $parsed['link'];
                    logToFile("forgotPassword Link set from parsed form (link): " . $_POST['Link']);
                }
            }
        }

        $usedLink = $_POST['Link'] ?? '';
        logToFile("forgotPassword using Link: " . $usedLink);

        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            logToFile("forgotPassword invalid or missing email: " . $email);
            echo json_encode(array(
                "status" => "error",
                "message" => "Email invalide ou manquant"
            ));
            return;
        }
        
        if (!$result) {
            echo json_encode(array(
                "status" => "error",
                "message" => "Aucun utilisateur trouvé avec cette adresse email."
            ));
            return;
        }

        // Générer un token unique
        $id = generateGUID();
        $part1 = generateGUID();
        $part2 = generateGUID();
        $resetToken = $part1 . '-' . $id . '-' . $part2;

        // Mettre à jour le token de réinitialisation dans la base de données
        $queryUpdate = 'UPDATE "users" SET "Token" = :reset_token WHERE "Email" = :email';
        $statementUpdate = $conn->prepare($queryUpdate);
        $statementUpdate->bindParam(':reset_token', $resetToken);
        $statementUpdate->bindParam(':email', $email);
        $resultUpdate = $statementUpdate->execute();
  
        if ($resultUpdate) {
            $linkReset = $_POST["Link"] . '/reset-password?token=' . $resetToken . '&email=' . urlencode($email);
            
            logToFile("forgotPassword generated resetToken: $resetToken for email: $email");
            logToFile("forgotPassword POST Link raw: " . ($_POST['Link'] ?? ($_POST['link'] ?? '')));
            logToFile("forgotPassword final reset link: " . $linkReset);
            logToFile("forgotPassword _POST: " . json_encode($_POST));
            logToFile("forgotPassword raw input (truncated): " . (isset($rawInput) ? substr($rawInput, 0, 2000) : ''));

            try {
                require_once(__DIR__ . '/SendMail.php');
                $emailO = $_POST["userEmail"];
                
                logToFile("forgotPassword calling sendMail with email: $emailO, link: $linkReset");
                $response = sendMail($_POST["userEmail"], "", 25, ['username' => "",'link' => $linkReset], $linkReset);

                logToFile("forgotPassword sendMail response: " . print_r($response, true));
                setJsonHeader();

                if (is_array($response)) {
                    echo json_encode($response);
                } else {
                    echo json_encode(array(
                        "status" => "error",
                        "message" => "Réponse invalide de sendMail",
                        "response" => $response
                    ));
                }
            } catch (Exception $e) {
                logToFile("forgotPassword sendMail exception: " . $e->getMessage());
                setJsonHeader();
                echo json_encode(array(
                    "status" => "error",
                    "message" => "Exception lors de l'envoi de l'email",
                    "details" => $e->getMessage()
                ));
            }
        } else {
            echo json_encode(array(
                "status" => "failure",
                "message" => "Échec de la mise à jour du token de réinitialisation.",
                "error" => $statementUpdate->errorInfo()
            ));
        }
    } catch (Exception $e) {
        setJsonHeader();
        echo json_encode(array(
            "status" => "error",
            "message" => "Erreur du serveur",
            "details" => $e->getMessage()
        ));
    }
}

function resetPassword($conn, $email, $newPassword, $token)
{
    try {
        $query = 'SELECT * FROM "users" WHERE "Email" = :email AND "Token" = :token';
        $statement = $conn->prepare($query);
        $statement->bindParam(':email', $email);
        $statement->bindParam(':token', $token);
        $statement->execute();
        $result = $statement->fetch(PDO::FETCH_ASSOC);

        setJsonHeader();

        if (!$result) {
            echo json_encode(array(
                "status" => "error",
                "message" => "Lien de réinitialisation invalide ou expiré."
            ));
            return;
        }

        $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);

        $queryUpdate = 'UPDATE "users" SET "Password" = :password, "Token" = NULL WHERE "Email" = :email';
        $statementUpdate = $conn->prepare($queryUpdate);
        $statementUpdate->bindParam(':password', $hashedPassword);
        $statementUpdate->bindParam(':email', $email);
        $resultUpdate = $statementUpdate->execute();

        if ($resultUpdate) {
            echo json_encode(array(
                "status" => "success",
                "message" => "Mot de passe mis à jour avec succès."
            ));
        } else {
            echo json_encode(array(
                "status" => "failure",
                "message" => "Échec de la mise à jour du mot de passe.",
                "error" => $statementUpdate->errorInfo()
            ));
        }
    } catch (Exception $e) {
        setJsonHeader();
        echo json_encode(array(
            "status" => "error",
            "message" => "Erreur du serveur",
            "details" => $e->getMessage()
        ));
    }
}

function readRecords($conn)
{
    $query = 'SELECT * FROM "TrainingType" ORDER BY "id" DESC';
    $statement = $conn->prepare($query);
    $statement->execute();
    $result = $statement->fetchAll(PDO::FETCH_ASSOC);
    setJsonHeader();
    if ($result) {
        echo json_encode(array("status" => "success", "trainingType" => $result));
    } else {
        http_response_code(500);
        echo json_encode(array("status" => "failure", "message" => "Failed to get records"));
    }
}

function getTableColumns($conn, $tableName)
{
    try {
        $query = "
                SELECT 
                    column_name, 
                    data_type, 
                    is_nullable
                FROM information_schema.columns
                WHERE table_name = :tableName
                ORDER BY ordinal_position;
            ";
        $statement = $conn->prepare($query);
        $statement->bindParam(':tableName', $tableName, PDO::PARAM_STR);
        $statement->execute();
        $columns = $statement->fetchAll(PDO::FETCH_ASSOC);

        setJsonHeader();
        if ($columns) {
            echo json_encode(array(
                "status" => "success",
                "columns" => $columns
            ));
        } else {
            echo json_encode(array(
                "status" => "error",
                "message" => "Aucune colonne trouvée pour la table spécifiée."
            ));
        }
    } catch (Exception $e) {
        setJsonHeader();
        echo json_encode(array(
            "status" => "error",
            "message" => "Erreur lors de la récupération des colonnes.",
            "details" => $e->getMessage()
        ));
    }
}

function getUserIdFromToken($conn, $email, $token)
{
    try {
        logToFile("getUserIdFromToken called with email: $email, token: $token");
        
        $query = 'SELECT "Id" FROM "users" WHERE "Email" = :email AND "Token" = :token';
        $statement = $conn->prepare($query);
        $statement->bindParam(':email', $email);
        $statement->bindParam(':token', $token);
        $statement->execute();
        $result = $statement->fetch(PDO::FETCH_ASSOC);

        setJsonHeader();
        if ($result) {
            logToFile("getUserIdFromToken success: ID found - " . $result['Id']);
            echo json_encode(array("status" => "success", "id" => $result['Id']));
        } else {
            logToFile("getUserIdFromToken error: No user found with this email and token");
            echo json_encode(array("status" => "error", "message" => "Token invalide ou expiré."));
        }
    } catch (PDOException $e) {
        logToFile("getUserIdFromToken exception: " . $e->getMessage());
        setJsonHeader();
        echo json_encode(array("status" => "error", "message" => "Erreur lors de la récupération : " . $e->getMessage()));
    }
}

function verifyEmailAndToken($conn, $email, $token)
{
    try {
        $query = 'SELECT "Id" FROM "users" WHERE "Email" = :email AND "Token" = :token';
        $statement = $conn->prepare($query);
        $statement->bindParam(':email', $email);
        $statement->bindParam(':token', $token);
        $statement->execute();
        $result = $statement->fetch(PDO::FETCH_ASSOC);

        if ($result) {
            $updateQuery = 'UPDATE "users" SET "Token" = :token, "isVerified" = :isVerified WHERE "Id" = :id';
            $updateStatement = $conn->prepare($updateQuery);
            $emptyToken = '';
            $isVerified = 1;
            $updateStatement->bindParam(':token', $emptyToken);
            $updateStatement->bindParam(':isVerified', $isVerified);
            $updateStatement->bindParam(':id', $result['Id']);
            $updateStatement->execute();

            echo json_encode(array("status" => "success", "message" => "Bienvenue", "id" => $result['Id']));
        } else {
            echo json_encode(array("status" => "error", "message" => "Le lien d'inscription est invalide ou expiré."));
        }
    } catch (PDOException $e) {
        echo json_encode(array("status" => "error", "message" => "Erreur lors de la vérification : " . $e->getMessage()));
    }
}

function readRecordsSearch($conn, $searchbar)
{
    $query = 'SELECT * FROM "Ad" WHERE LOWER("title") LIKE :searchbar  ORDER BY "createdAt" DESC';
    $statement = $conn->prepare($query);
    $statement->bindValue(':searchbar', '%' . $searchbar . '%');
    $statement->execute();
    $result = $statement->fetchAll(PDO::FETCH_ASSOC);

    $query1 = 'SELECT * FROM "AdType" ORDER BY "id" DESC';
    $statement1 = $conn->prepare($query1);
    $statement1->execute();
    $result1 = $statement1->fetchAll(PDO::FETCH_ASSOC);
    setJsonHeader();

    if ($result) {
        echo json_encode(array("status" => "success", "ad" => $result, "adType" => $result1));
    } else {
        http_response_code(500);
        echo json_encode(array("status" => "failure", "message" => "Failed to get records"));
    }
}

function readRecordsPaginate($conn, $page)
{
    $query = 'SELECT * FROM "Reservation" ORDER BY "createdAt" DESC LIMIT 10 OFFSET (:page - 1) * 10';
    $statement = $conn->prepare($query);
    $statement->bindParam(':page', $page);
    $statement->execute();
    $result = $statement->fetchAll(PDO::FETCH_ASSOC);
    setJsonHeader();
    if ($result) {
        echo json_encode(array("status" => "success", "data" => $result));
    } else {
        http_response_code(500);
        echo json_encode(array("status" => "failure", "message" => "Failed to get records"));
    }
}

function readRecordsPaginateSize($conn)
{
    $query = 'SELECT COUNT(*) as totalRows, CEILING(COUNT(*) / 10) as totalPages FROM "Reservation"';
    $statement = $conn->prepare($query);
    $statement->execute();
    $result = $statement->fetchAll(PDO::FETCH_ASSOC);
    setJsonHeader();
    if ($result) {
        echo json_encode(array("status" => "success", "data" => $result));
    } else {
        http_response_code(500);
        echo json_encode(array("status" => "failure", "message" => "Failed to get records"));
    }
}

function readRecord($conn, $email, $password)
{
    $query = 'SELECT * FROM "users" WHERE "Email" = :email';
    $statement = $conn->prepare($query);
    $statement->bindParam(':email', $email);
    $statement->execute();
    $result = $statement->fetch(PDO::FETCH_ASSOC);

    setJsonHeader();

    if ($result) {
        if (password_verify($password, $result['Password'])) {
            echo json_encode(array(
                "status" => "success",
                "message" => "Connexion réussie",
                "isVerified" => $result['isVerified'],
                "id" => $result['Id']
            ));
        } else {
            echo json_encode(array("status" => "error", "message" => "Mot de passe incorrect"));
        }
    } else {
        echo json_encode(array("status" => "error", "message" => "Aucun compte associé à cette adresse email. Veuillez en créer un ou nous contacter"));
    }
}

function readRecordByName($conn, $category)
{
    $query = 'SELECT * FROM "AdType" where name = :name';
    $statement = $conn->prepare($query);
    $statement->bindParam(':name', $category);
    $statement->execute();
    $result = $statement->fetch(PDO::FETCH_ASSOC);
    setJsonHeader();
    if ($result) {
        echo json_encode(array("status" => "success", "adType" => $result));
    } else {
        http_response_code(500);
        echo json_encode(array("status" => "failure", "message" => "Failed to get record"));
    }
}

function deleteRecord($conn, $email)
{
    try {
        $query = 'DELETE FROM "users" WHERE "Email" = :email';
        $statement = $conn->prepare($query);
        $statement->bindParam(':email', $email);
        $statement->execute();

        setJsonHeader();

        if ($statement->rowCount() > 0) {
            echo json_encode(array("status" => "success", "message" => "Utilisateur supprimé avec succès"));
        } else {
            echo json_encode(array("status" => "error", "message" => "Utilisateur non trouvé"));
        }
    } catch (Exception $e) {
        setJsonHeader();
        echo json_encode(array("status" => "error", "message" => "Erreur lors de la suppression : " . $e->getMessage()));
    }
}

function updateRecord($conn, $id, $data)
{
    $columns = array_keys($data);
    $values = array_values($data);

    $quotedColumns = array_map(function ($column) {
        return "\"$column\"";
    }, $columns);

    $setClause = "";
    for ($i = 0; $i < count($quotedColumns); $i++) {
        $setClause .= $quotedColumns[$i] . " = ?";
        if ($i < count($quotedColumns) - 1) {
            $setClause .= ", ";
        }
    }

    $query = "UPDATE \"Reservation\" SET $setClause WHERE uid = ?";

    $statement = $conn->prepare($query);

    for ($i = 0; $i < count($values); $i++) {
        $statement->bindValue(($i + 1), $values[$i]);
    }
    $statement->bindValue(count($values) + 1, $id);

    $result = $statement->execute();
    setJsonHeader();

    if ($result) {
        echo json_encode(array("status" => "success", "message" => "Record successfully update"));
    } else {
        http_response_code(500);
        echo json_encode(array("status" => "failure", "message" => "Failed to update record"));
    }
}

function readRecordsByUserId($conn, $id)
{
    $query = 'SELECT * FROM "users" WHERE LOWER("Id") LIKE :id';
    $statement = $conn->prepare($query);
    $statement->bindValue(':id', '%' . strtolower($id) . '%');

    try {
        $statement->execute();
        $result = $statement->fetchAll(PDO::FETCH_ASSOC);

        setJsonHeader();

        if ($result) {
            echo json_encode(array("status" => "success", "profile" => $result));
        } else {
            http_response_code(404);
            echo json_encode(array("status" => "failure", "message" => "No records found."));
        }
    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(array("status" => "failure", "message" => "Database error: " . $e->getMessage()));
    }
}

// Vérifier la méthode et appeler la fonction appropriée
if ($method == 'create') {
    createRecord($conn, $email, $password);
} elseif ($method == 'readAllByUserId') {
    readRecordsByUserId($conn, $id);
} elseif ($method == 'readAll') {
    readRecords($conn);
} elseif ($method == 'getTableColumns') {
    getTableColumns($conn, $tableName);
} elseif ($method == 'resetPassword') {
    forgotPassword($conn, $email);
} elseif ($method == 'updatePassword') {
    resetPassword($conn, $email, $newPassword, $token);
} elseif ($method == 'getUserIdFromToken') {
    getUserIdFromToken($conn, $email, $token);
} elseif ($method == 'verify') {
    verifyEmailAndToken($conn, $email, $token);
} elseif ($method == 'read') {
    readRecord($conn, $email, $password);
} elseif ($method == 'readByName') {
    readRecordByName($conn, $category);
} elseif ($method == 'update') {
    updateRecord($conn, $id, $data);
} elseif ($method == 'delete') {
    deleteRecord($conn, $email);
} elseif ($method == 'deleteAccount') {
    $userId = $_POST['userId'];

    if (empty($userId)) {
        setJsonHeader();
        echo json_encode(["status" => "error", "message" => "Invalid ID"]);
        exit;
    }

    try {
        $conn->beginTransaction();

        $query = 'SELECT * FROM "userInfo" WHERE userid = :userId';
        $statement = $conn->prepare($query);
        $statement->bindValue(':userId', $userId, PDO::PARAM_STR);
        $statement->execute();
        $userInfo = $statement->fetch(PDO::FETCH_ASSOC);

        if (!$userInfo) {
            setJsonHeader();
            echo json_encode(["status" => "error", "message" => "UserInfo not found"]);
            exit;
        }

        $query = 'SELECT * FROM "users" WHERE "Id" = :userId';
        $statement = $conn->prepare($query);
        $statement->bindValue(':userId', $userId);
        $statement->execute();
        $user = $statement->fetch(PDO::FETCH_ASSOC);

        if (!$user) {
            setJsonHeader();
            echo json_encode(["status" => "error", "message" => "User not found"]);
            exit;
        }

        function deleteFileIfExists($filePath)
        {
            if (!empty($filePath) && file_exists($filePath)) {
                if (!unlink($filePath)) {
                    // error_log("Impossible de supprimer le fichier : " . $filePath);
                }
            }
        }

        $query = 'SELECT urlimg FROM "imageDiapo" WHERE userid = :userId';
        $statement = $conn->prepare($query);
        $statement->bindValue(':userId', $userId);
        $statement->execute();
        $images = $statement->fetchAll(PDO::FETCH_ASSOC);

        foreach ($images as $img) {
            deleteFileIfExists($img['urlimg']);
        }

        $query = 'SELECT id FROM "ads" WHERE "userId" = :userId AND "deletedat" IS NULL';
        $statement = $conn->prepare($query);
        $statement->bindValue(':userId', $userId);
        $statement->execute();
        $ads = $statement->fetchAll(PDO::FETCH_ASSOC);

        foreach ($ads as $ad) {
            $query = 'SELECT urlimg FROM "imageAnnonce" WHERE annonceid = :annonceid';
            $statement = $conn->prepare($query);
            $statement->bindValue(':annonceid', $ad['id']);
            $statement->execute();
            $images = $statement->fetchAll(PDO::FETCH_ASSOC);

            foreach ($images as $img) {
                deleteFileIfExists($img['urlimg']);
            }

            $query = "DELETE FROM \"imageAnnonce\" WHERE annonceid = :annonceid";
            $statement = $conn->prepare($query);
            $statement->bindValue(':annonceid', $ad['id']);
            $statement->execute();
        }

        $query = "UPDATE \"ads\" SET \"deletedat\" = CURRENT_TIMESTAMP WHERE \"userId\" = :userId";
        $statement = $conn->prepare($query);
        $statement->bindValue(':userId', $userId);
        $statement->execute();

        $query = "DELETE FROM \"notifications\" WHERE user_id = :userId";
        $statement = $conn->prepare($query);
        $statement->bindValue(':userId', $userId);
        $statement->execute();

        $tablesToDeleteFrom = ['user_coins', 'history_coins', 'favoris', 'imageDiapo'];
        foreach ($tablesToDeleteFrom as $table) {
            $query = "DELETE FROM \"$table\" WHERE userid = :userId";
            $statement = $conn->prepare($query);
            $statement->bindValue(':userId', $userId);
            $statement->execute();
        }

        $query = 'DELETE FROM "userInfo" WHERE userid = :userId';
        $statement = $conn->prepare($query);
        $statement->bindValue(':userId', $userId);
        $statement->execute();

        $query = 'DELETE FROM "users" WHERE "Id" = :userId';
        $statement = $conn->prepare($query);
        $statement->bindValue(':userId', $userId);
        $statement->execute();

        $conn->commit();

        $notificationManager = new NotificationBrevoAndWeb($conn);
        if ($userInfo['profiletype'] == 'particulier') {
            $notificationManager->sendNotificationDeleteAccountParticulier($userId);
        } else if ($userInfo['profiletype'] == 'professionnel') {
            $notificationManager->sendNotificationDeleteAccountProfessionnel($userId);
        }

        setJsonHeader();
        echo json_encode(["status" => "success", "message" => "Account deleted successfully"]);
    } catch (Exception $e) {
        $conn->rollBack();
        setJsonHeader();
        echo json_encode(["status" => "error", "message" => "An error occurred: " . $e->getMessage()]);
    }
} elseif ($method == 'deleteFile') {
    $filePath = "./img/05afb5b1-0701-4764-9c60-dd6cd832d5ff.png";

    function deleteFileIfExists($filePath)
    {
        if (file_exists($filePath)) {
            unlink($filePath);
            setJsonHeader();
            echo json_encode(["status" => "success", "message" => "IN Image delelted"]);
            exit;
        } else {
            setJsonHeader();
            echo json_encode(["status" => "error", "message" => "Image not found"]);
            exit;
        }
    }

    deleteFileIfExists($filePath);

    setJsonHeader();
    echo json_encode(["status" => "success", "message" => "Image deleted successfully"]);
    exit;
} elseif ($method == 'paginate') {
    readRecordsPaginate($conn, $page);
} elseif ($method == 'paginateSize') {
    readRecordsPaginateSize($conn);
} else if ($method == 'searchbar') {
    readRecordsSearch($conn, $searchbar);
}
