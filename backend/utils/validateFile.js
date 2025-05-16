const validateFile = (file) => {
  if (!file) {
    return 'No file provided';
  }

  // Check file size (5MB limit)
  const maxSize = 5 * 1024 * 1024; // 5MB in bytes
  if (file.size > maxSize) {
    return 'File size exceeds 5MB limit';
  }

  // Check file type
  const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg'];
  if (!allowedTypes.includes(file.mimetype)) {
    return 'Invalid file type. Only JPEG, JPG, and PNG files are allowed';
  }

  return null;
};

module.exports = {
  validateFile
}; 