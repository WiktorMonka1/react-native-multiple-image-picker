///
/// JCameraResult.hpp
/// This file was generated by nitrogen. DO NOT MODIFY THIS FILE.
/// https://github.com/mrousavy/nitro
/// Copyright © 2024 Marc Rousavy @ Margelo
///

#pragma once

#include <fbjni/fbjni.h>
#include "CameraResult.hpp"

#include "JResultType.hpp"
#include "ResultType.hpp"
#include <optional>
#include <string>

namespace margelo::nitro::multipleimagepicker {

  using namespace facebook;

  /**
   * The C++ JNI bridge between the C++ struct "CameraResult" and the the Kotlin data class "CameraResult".
   */
  struct JCameraResult final: public jni::JavaClass<JCameraResult> {
  public:
    static auto constexpr kJavaDescriptor = "Lcom/margelo/nitro/multipleimagepicker/CameraResult;";

  public:
    /**
     * Convert this Java/Kotlin-based struct to the C++ struct CameraResult by copying all values to C++.
     */
    [[maybe_unused]]
    CameraResult toCpp() const {
      static const auto clazz = javaClassStatic();
      static const auto fieldPath = clazz->getField<jni::JString>("path");
      jni::local_ref<jni::JString> path = this->getFieldValue(fieldPath);
      static const auto fieldType = clazz->getField<JResultType>("type");
      jni::local_ref<JResultType> type = this->getFieldValue(fieldType);
      static const auto fieldWidth = clazz->getField<jni::JDouble>("width");
      jni::local_ref<jni::JDouble> width = this->getFieldValue(fieldWidth);
      static const auto fieldHeight = clazz->getField<jni::JDouble>("height");
      jni::local_ref<jni::JDouble> height = this->getFieldValue(fieldHeight);
      static const auto fieldDuration = clazz->getField<jni::JDouble>("duration");
      jni::local_ref<jni::JDouble> duration = this->getFieldValue(fieldDuration);
      static const auto fieldThumbnail = clazz->getField<jni::JString>("thumbnail");
      jni::local_ref<jni::JString> thumbnail = this->getFieldValue(fieldThumbnail);
      static const auto fieldFileName = clazz->getField<jni::JString>("fileName");
      jni::local_ref<jni::JString> fileName = this->getFieldValue(fieldFileName);
      return CameraResult(
        path->toStdString(),
        type->toCpp(),
        width != nullptr ? std::make_optional(width->value()) : std::nullopt,
        height != nullptr ? std::make_optional(height->value()) : std::nullopt,
        duration != nullptr ? std::make_optional(duration->value()) : std::nullopt,
        thumbnail != nullptr ? std::make_optional(thumbnail->toStdString()) : std::nullopt,
        fileName != nullptr ? std::make_optional(fileName->toStdString()) : std::nullopt
      );
    }

  public:
    /**
     * Create a Java/Kotlin-based struct by copying all values from the given C++ struct to Java.
     */
    [[maybe_unused]]
    static jni::local_ref<JCameraResult::javaobject> fromCpp(const CameraResult& value) {
      return newInstance(
        jni::make_jstring(value.path),
        JResultType::fromCpp(value.type),
        value.width.has_value() ? jni::JDouble::valueOf(value.width.value()) : nullptr,
        value.height.has_value() ? jni::JDouble::valueOf(value.height.value()) : nullptr,
        value.duration.has_value() ? jni::JDouble::valueOf(value.duration.value()) : nullptr,
        value.thumbnail.has_value() ? jni::make_jstring(value.thumbnail.value()) : nullptr,
        value.fileName.has_value() ? jni::make_jstring(value.fileName.value()) : nullptr
      );
    }
  };

} // namespace margelo::nitro::multipleimagepicker
