<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * Localized language
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'wordpress' );

/** Database username */
define( 'DB_USER', 'wp_user' );

/** Database password */
define( 'DB_PASSWORD', 'StR0nG_P4s5w0rd_123!' );

/** Database hostname */
define( 'DB_HOST', 'mariadb' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',          'o7pKcCo]uEsB]r_r19^z?TJXk!arEI5k.T7&.G/B9?&`wH`*+WM}#[pclFR KB,j' );
define( 'SECURE_AUTH_KEY',   'jrMkbn.P#`%3|y<+*,/rYpKyst>chz(Cu#tQB;FZ%O[Gh7su%@0K5Ah5;hlta]VW' );
define( 'LOGGED_IN_KEY',     '4kvB5gn@FjGbwNcJ6GVu<0`9ob!K:u~@FVkUe-44tS,mG:}ek6|AV}cOy0wfP$*,' );
define( 'NONCE_KEY',         'wVnYdak4}cluPt_jof+% W,RGu`P{ApKB8+{lv9dp9// v4U{O7mvcwJi.5-m8v.' );
define( 'AUTH_SALT',         '_,-2|vX|Q9H:?dW6@;y%o`!f>Iv:_,}(@B`O~^`W1;6xRBg>=zSX:$9)M3s%xr(:' );
define( 'SECURE_AUTH_SALT',  'YDsbOtzQs7YPhg?VxdZv{g8M4}TD_s2XII=*^;6HJ9-6sDdvej7}Tm>,dAh$G`TJ' );
define( 'LOGGED_IN_SALT',    'F}-b6!C}(vQjo]m^#H#m7y`h1;uFSfB:6IC;_Z8>C&7`;yNR6e+m%>GgVaK6EZ8^' );
define( 'NONCE_SALT',        '(BDC6kaDpSSk4sZ,i3i9uq_G+S%AXeJl{KFac?8D?u }HH}Ty*Riq4C3U_(H& q+' );
define( 'WP_CACHE_KEY_SALT', '){IoRWh)hn2N^lC!^{k 6mX+3FAZ;4*.$A=f!nrT(2uzp0f!aMF+O]).)5POQ 1;' );


/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';


/* Add any custom values between this line and the "stop editing" line. */



/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
if ( ! defined( 'WP_DEBUG' ) ) {
	define( 'WP_DEBUG', false );
}

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
