#include <iostream>
#include <string>
#include <fstream>
#include <sstream>

using namespace std;

const int MAX_LEN = 50;
const int BASE = 1000;
const int BASE_L = 3;

struct BigNum {
	int len;
	int parts[MAX_LEN];
};

void trunc(BigNum &m) {
	for (; m.parts[m.len - 1] == 0 && m.len > 1; m.len--);
}

string big2str(BigNum &m) {
	string result;
	for (int i = m.len - 1; i >= 0; i--) {
		int pad =  BASE_L - to_string(m.parts[i]).length();
		if (pad > 0 && i != m.len - 1) {
			result += string(pad, '0');
		}
		result += to_string(m.parts[i]);
	}
	return result;
}

bool equal(const BigNum &m, const BigNum &n) {
	if (m.len != n.len) {
		return false;
	}
	for (int i = m.len; i >= 0; i--) {
		if (m.parts[i] != n.parts[i]) {
			return false;
		}
	}
	return true;
}

bool normalize(BigNum &m, BigNum &n) {
	if (m.len < n.len) {
		swap(m, n);
		return true;
	}
	if (m.len == n.len) {
		for (int i = m.len - 1; i >= 0; i--) {
			if (m.parts[i] < n.parts[i]) {
				swap(m, n);
				return true;
			}
			else if (m.parts[i] > n.parts[i]) {
				return false;
			}
		}
	}
	return false;
}

void substract(BigNum &m, const BigNum &n) {
	int carry = 0;
	for (int i = 0; i < n.len || carry > 0; i++) {
		m.parts[i] -= n.parts[i] + carry;
		if (m.parts[i] < 0) {
			carry = 1;
			m.parts[i] += BASE;
		} else {
			carry = 0;
		}
	}
	trunc(m);
}

int divide2all(BigNum &m) {
	int count = 0;
	while (m.parts[0] % 2 == 0) {
		int carry = 0;
		for (int i = m.len - 1; i >= 0; i--) {
			int carry_temp = carry;
			carry = (m.parts[i] % 2) * BASE / 2;
			m.parts[i] /= 2;
			m.parts[i] += carry_temp;
		}
		count++;
	}
	trunc(m);
	return count;
}

void multiply(BigNum &m, int n) {
	int carry = 0;
	for (int i = 0; i < m.len; i++) {
		m.parts[i] *= n;
		m.parts[i] += carry;
		if (m.parts[i] > BASE) {
			carry = m.parts[i] / BASE;
			m.parts[i] %= BASE;
			if (i == m.len - 1) {
				m.len++;
			}
		} else {
			carry = 0;
		}
	}
}

uint64_t gcd_normal(const uint64_t a, const uint64_t b) {
	uint64_t p = a;
	uint64_t q = b;
	if (p == 0) {
		return q;
	}
	if (q == 0) {
		return p;
	}
	uint64_t r = p % q;
	while (r != 0) {
		p = q;
		q = r;
		r = p % q;
	}
	return q;
}

int gcd_shim(BigNum &m, BigNum &n) {
	return gcd_normal(stoi(big2str(m)), stoi(big2str(n)));
}

BigNum gcd(BigNum &m, BigNum &n) {
	// Stein's binary GCD algorithm
	BigNum zero = {1, {0}};
	// Extract common factor-2: gcd(2ⁱ n, 2ⁱ m) = 2ⁱ gcd(n, m)
	// and reducing until odd gcd(2ⁱ n, m) = gcd(n, m) if m is odd
	int k = min(divide2all(n), divide2all(m));

	while (true) {
		normalize(m, n);
		// Using identity 4 (gcd(n, m) = gcd(|m-n|, min(n, m))
		substract(m, n);

		// Identity 1: gcd(n, 0) = n
		// The shift by k is necessary to add back the 2ᵏ factor that was removed before the loop
		if (equal(m, zero)) {
			multiply(n, 1<<k);
			return n;
		}

		// Identity 3: gcd(n, 2ʲ m) = gcd(n, m) (n has not changed since the beginning of the loop, so it is still known to be odd)
		divide2all(m);
	}
}

void init(BigNum &m, string s) {
	m.len = 0;
	for (int i = s.length(), chunk = 0; i > 0; i -= BASE_L, chunk++, m.len++) {
		m.parts[chunk] = stoi(s.substr(max(i-BASE_L, 0), min(BASE_L, i)));
	}
}

int main() {
	ifstream bignums("bignums.txt");
	for (string line; getline(bignums, line);) {
		cout << line << endl;
		istringstream ss(move(line));
		BigNum nums [2];
		int i = 0;
		for (string value; getline(ss, value, ' '); i++) {
			init(nums[i], value);
		}
		BigNum answer = gcd(nums[0], nums[1]);
		cout << big2str(answer);
		cout << endl;
	}

	return 0;
}